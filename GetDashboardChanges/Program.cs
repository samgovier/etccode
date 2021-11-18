using System;
using System.Net.Http;
using System.Net;
using System.Collections.Generic;
using System.IO;

/// <summary>
/// GetDashboardChanges scrapes the Dashboard to output current alerts in each section. It also
/// writes a baseline as requested by the user: if the baseline exists on scrape, it will output
/// the diff in amount of alerts, so the user can see what changes have occurred in the amount
/// of alerts since the last run.
/// </summary>
namespace GetDashboardChanges
{
    /// <summary>
    /// This is just a simple executable program
    /// </summary>
    class Program
    {
        /// <summary>
        /// BASELINE_FILE is the full path of the file to be written and read alongside the executable
        /// </summary>
        static string BASELINE_FILE = System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\DashboardBaseline.txt";

        /// <summary>
        /// DASHBOARD_URL is the url to hit for scraping the Dashboard
        /// </summary>
        static string DASHBOARD_URL = "https://example.com/Dashboard_serverState/serverstate.aspx";

        /// <summary>
        /// AUTH_HEADER is the Authorization header used when making requests to the Dashboard
        /// </summary>
        static string AUTH_HEADER = null;

        /// <summary>
        /// DashboardScrape performs requests to the dashboard to get the alert information, and then formats it
        /// into a string array that prints into a table.
        /// </summary>
        /// <returns>string array table</returns>
        private static string[] DashboardScrape()
        {
            // scrapeData is the array that will contain the table rows and will be returned
            string[] scrapeData = new string[24];

            // viewStateContent is a variable to contain the data of the original request
            string viewStateContent = string.Empty;

            // construct http client
            HttpClientHandler handler = new HttpClientHandler();
            handler.CookieContainer = new CookieContainer();
            HttpClient client = new HttpClient(handler);

            // add authorization header
            client.DefaultRequestHeaders.Add("Authorization", AUTH_HEADER);


            HttpResponseMessage viewStateResponse;
            // basic request to dashboard to get viewState tokens
            try
            {
                viewStateResponse = client.GetAsync(DASHBOARD_URL).Result;
            }
            catch
            {
                viewStateResponse = null;
            }

            // if the response fails, write the failure and return
            if (null == viewStateResponse || !viewStateResponse.IsSuccessStatusCode)
            {
                Console.WriteLine("Initial Request Failed.");

                if (null != viewStateResponse)
                {
                    Console.WriteLine(viewStateResponse.ReasonPhrase);
                }
                else
                {
                    Console.WriteLine("Could not reach server.");
                }

                return scrapeData;
            }

            // get the view state data
            viewStateContent = viewStateResponse.Content.ReadAsStringAsync().Result;

            //Pull viewState tokens
            int viewStateTokenStart = viewStateContent.IndexOf("id=\"__VIEWSTATE\" value=\"");
            string vsToken = viewStateContent.Substring(viewStateTokenStart + 24, 76);
            int viewStateGenTokenStart = viewStateContent.IndexOf("id=\"__VIEWSTATEGENERATOR\" value=\"");
            string vsgToken = viewStateContent.Substring(viewStateGenTokenStart + 33, 8);

            // Format an encodedContent body to pass tokens and get actual alert information
            FormUrlEncodedContent content = new FormUrlEncodedContent(new[]
            {
             new KeyValuePair<string, string>("__VIEWSTATE", vsToken),
             new KeyValuePair<string, string>("__VIEWSTATEGENERATOR", vsgToken),
             new KeyValuePair<string, string>("hdClientUTC", "360"),
             new KeyValuePair<string, string>("hdClientUTCFill", "ok")
            });

            // timestamp on pulling data
            string timestamp = DateTime.Now.ToString();

            HttpResponseMessage dashResponse;
            // pull alert data
            try
            {
                dashResponse = client.PostAsync(DASHBOARD_URL, content).Result;
            }
            catch
            {
                Console.WriteLine("Failed to make a second request. Exiting.");
                return scrapeData;
            }

            // if the response doesn't fail, continue to format the data
            if (dashResponse.IsSuccessStatusCode)
            {
                // serverNames is the environments as listed in the Dashboard
                string[] serverNames = {
                    };

                // dashContent is the content from the request
                string dashContent = dashResponse.Content.ReadAsStringAsync().Result;

                // write the timestamp and table headers
                scrapeData[0] = timestamp;
                scrapeData[1] = string.Format("|{0,-28}|{1,-10}|{2,-10}|", "(Environment)", "State", "Diff");
                scrapeData[2] = string.Format("|{0,-28}|{1,-10}|{2,-10}|", "", "", "");

                // scrape for each environment
                for (int i = 0; i < serverNames.Length; i++)
                {
                    // find the environment name and skip to the alert info in the HTML
                    int curEnvIndex = dashContent.IndexOf(serverNames[i]);
                    int startStateIndex = dashContent.IndexOf('(', curEnvIndex + 1);

                    // hack to skip (SG) for Singapore Azure
                    if (dashContent.Substring(startStateIndex, 3) == "(SG")
                    {
                        startStateIndex = dashContent.IndexOf('(', startStateIndex + 1);
                    }

                    // find the end of the alert info in the HTML
                    int endStateIndex = dashContent.IndexOf(')', startStateIndex);

                    // trim alert text into a string
                    string alertText = dashContent.Substring(startStateIndex, endStateIndex - startStateIndex);

                    // the actual number of alerts: set to -1 to denote an error
                    int alertNumber = -1;

                    // if we're tracking comments (eg. ( 3/ 4)), pull only the second number. Otherwise pull the only number
                    if (alertText.Contains('/'))
                    {
                        alertNumber = int.Parse((alertText.Substring(alertText.IndexOf('/') + 1)).Trim());
                    }
                    else
                    {
                        alertNumber = int.Parse(alertText.Trim('(').Trim());
                    }

                    // add the row for this environment to the scrape array
                    scrapeData[i + 3] = string.Format("|{0,-28}|{1,-10}|{2,-10}|", serverNames[i], alertNumber, "NA");
                }

                // if there is a previous scrape written, read the file to determine the diff in alerts
                if(File.Exists(BASELINE_FILE))
                {
                    using (StreamReader sr = new StreamReader(BASELINE_FILE))
                    {
                        // skip the header lines
                        sr.ReadLine();
                        sr.ReadLine();
                        sr.ReadLine();

                        // for each server, determine the diff in alerts from this time to last time and replace NA with that
                        for (int i = 0; i < serverNames.Length; i++)
                        {
                            string prevScrapeLine = sr.ReadLine();
                            // if the file is screwed up, skip: otherwise replace with diff
                            if (prevScrapeLine.Length != 0)
                            {
                                int lastVal = int.Parse(prevScrapeLine.Split('|')[2].Trim());
                                int diff = int.Parse(scrapeData[i + 3].Split('|')[2].Trim()) - lastVal;
                                scrapeData[i + 3] = scrapeData[i + 3].Replace("NA", diff.ToString());
                            }
                        }
                    }
                }
            }

            return scrapeData;
        }

        /// <summary>
        /// GetAuthHeader pulls username and password to get authorization information
        /// </summary>
        /// <returns></returns>
        private static string GetAuthHeader()
        {
            // pull username
            Console.Write("Enter your username: ");
            string user = Console.ReadLine();

            // add @example.com if needed
            user = user.EndsWith("@example.com")? user : string.Concat(user, "@example.com");

            // pull password
            Console.Write("Enter your password: ");
            string pass = string.Empty;

            // key tracks the current key being set in the console
            ConsoleKey key;

            // while we're not pressing enter
            do
            {
                ConsoleKeyInfo keyInfo = Console.ReadKey(intercept: true);
                key = keyInfo.Key;

                // if we're using backspace, remove from the password array
                if (key == ConsoleKey.Backspace && pass.Length > 0)
                {
                    Console.Write("\b \b");
                    pass = pass[0..^1];
                }

                // if we don't use a control character, write an asterisk and add the character to the password string
                else if (!char.IsControl(keyInfo.KeyChar))
                {
                    Console.Write("*");
                    pass += keyInfo.KeyChar;
                }
            } while (key != ConsoleKey.Enter);

            // add a line for space
            Console.WriteLine();

            // return the authorization header
            return "Basic " + Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(user + ":" + pass));
        }

        /// <summary>
        /// WriteScrape creates the output file using the name BASELINE_FILE along the executable
        /// </summary>
        /// <param name="scrapeData">scrapeData is what will be written</param>
        private static void WriteScrape(string[] scrapeData)
        {
            // open a stream writer and write the data
            using (StreamWriter sw = new StreamWriter(BASELINE_FILE, false))
            {
                foreach(string s in scrapeData)
                {
                    sw.WriteLine(s);
                }
                Console.WriteLine("Write completed at {0}.", DateTime.Now.ToString());
            }
        }

        /// <summary>
        /// ReadBaseline returns the first two columns of the previous scrape, if it exists
        /// </summary>
        /// <returns>string array table</returns>
        private static string[] ReadBaseline()
        {
            // baseline is the collection of strings, removing the diff
            string[] baseline = new string[24];

            // if there is a previous scrape written, read the file, else no scrape found
            if (File.Exists(BASELINE_FILE))
            {
                using (StreamReader sr = new StreamReader(BASELINE_FILE))
                {
                    // skip the timestamp
                    baseline[0] = sr.ReadLine();

                    // for each line, if the file isn't screwed up, return only the env and state
                    for (int i = 1; i < baseline.Length - 1; i++)
                    {
                        string tableline = sr.ReadLine();
                        if (tableline.Length != 0)
                        {
                            baseline[i] = tableline.Substring(0, tableline.IndexOf('|', 37) + 1);
                        }
                    }
                }
            }
            else
            {
                baseline[0] = "No previous scrape found.";
            }

            return baseline;
        }

        /// <summary>
        /// Main process is a shell with options for getting dashboard changes.
        /// </summary>
        /// <param name="args">unused</param>
        static void Main(string[] args)
        {
            // set the creds on program start
            AUTH_HEADER = GetAuthHeader();

            while (true)
            {
                Console.Write("GetDashboardChanges> ");
                string cons = Console.ReadLine();

                switch (cons.ToLower())
                {
                    case "help":
                        ShellHelp();
                        break;
                    case "exit":
                    case "quit":
                        return;
                    case "scrape":
                        ShellScrape();
                        break;
                    case "get":
                        ShellGet();
                        break;
                    case "set":
                        ShellSet();
                        break;
                    case "creds":
                        ShellCreds();
                        break;
                    default:
                        Console.WriteLine("Invalid command: {0}\nType \"help\" for a list.", cons.ToUpper());
                        break;
                }
            }
        }

        /// <summary>
        /// scrape the dashboard and compare to the current baseline
        /// </summary>
        private static void ShellScrape()
        {
            // scrapeData calls the Dashboard Scraping function and stores it to array
            string[] scrapeData = DashboardScrape();

            // oldStamp pulls the current baseline to get the old timestamp
            string oldStamp = ReadBaseline()[0];

            // Write for timeline
            Console.WriteLine("FROM\n" + oldStamp + "\nTO");

            // else, we can write the scrape information
            foreach (string s in scrapeData)
            {
                if (!string.IsNullOrWhiteSpace(s)) { Console.WriteLine(s); }
            }
        }

        /// <summary>
        /// pull the current baseline in use
        /// </summary>
        private static void ShellGet()
        {
            string[] getBase = ReadBaseline();
            
            foreach(string s in getBase)
            {
                if (!string.IsNullOrWhiteSpace(s)) { Console.WriteLine(s); }
            }
        }

        /// <summary>
        /// scrape and write as the new baseline
        /// </summary>
        private static void ShellSet()
        {
            WriteScrape(DashboardScrape());
        }

        /// <summary>
        /// set the auth header
        /// </summary>
        private static void ShellCreds()
        {
            AUTH_HEADER = GetAuthHeader();
        }

        /// <summary>
        /// print the help text
        /// </summary>
        private static void ShellHelp()
        {
            Console.WriteLine("Commands:");
            Console.WriteLine("\tscrape\tscrape the dashboard and show diff from current baseline");
            Console.WriteLine("\tset\tscrapes and set the baseline");
            Console.WriteLine("\tget\tgets the current baseline (ignore diff in this case)");
            Console.WriteLine("\tcreds\tset credentials for example.com");
            Console.WriteLine("\thelp\toutput command helptext");
            Console.WriteLine("\texit\texit GetDashboardChanges");
            Console.WriteLine("\tquit\tsame as exit");
        }
    }
}
