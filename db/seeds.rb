hackclub_user = User.find_or_create_by!(provider: "hackclub", uid: "system") do |u|
  u.email = "system@hackclub.com"
  u.name = "Hackclub System"
  u.role = "admin"
end

hackclub_org = Organisation.find_or_create_by!(name: "Hackclub") do |o|
  o.user = hackclub_user
  o.signing_user = hackclub_user
  o.self_found = true
end

unless hackclub_org.join_requirements == "omniauth hackclub"
  hackclub_org.update!(join_requirements: "omniauth hackclub")
end
