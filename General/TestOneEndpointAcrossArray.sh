machines=(
    
)

for mach in "${machines[@]}"; do
    ssh $mach -o "StrictHostKeyChecking no" "hostname; echo '==='; curl -k https://example.com; echo; echo '==='"
done