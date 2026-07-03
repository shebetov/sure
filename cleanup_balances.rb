family = Family.first
puts "=" * 80
puts "BALANCE CLEANUP: Purging & recalculating for #{family.name}"
puts "=" * 80

total_deleted = 0
total_accounts = family.accounts.count

family.accounts.each_with_index do |account, idx|
  puts "\n[#{idx + 1}/#{total_accounts}] Processing: #{account.name}"
  
  deleted = account.balances.where("date >= ?", Date.parse("2026-06-28")).delete_all
  total_deleted += deleted
  puts "  Deleted #{deleted} stale balances"
  
  puts "  Recalculating balances..."
  start_time = Time.now
  Balance::Materializer.new(account, strategy: :forward).materialize_balances
  elapsed = ((Time.now - start_time) * 1000).round
  puts "  ✓ Recalculated (#{elapsed}ms)"
end

puts "\n" + "=" * 80
puts "✓ CLEANUP COMPLETE"
puts "  Total balances deleted: #{total_deleted}"
puts "  Accounts recalculated: #{total_accounts}"
puts "=" * 80
