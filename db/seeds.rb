abort "Local development seeds only run in development." unless Rails.env.development?

password = "password"

maya = User.find_or_create_by!(email_address: "maya@example.test") do |user|
  user.password = password
  user.password_confirmation = password
end

leo = User.find_or_create_by!(email_address: "leo@example.test") do |user|
  user.password = password
  user.password_confirmation = password
end

article = maya.captures.find_or_create_by!(title: "A thoughtful article") do |capture|
  capture.source_url = "https://example.com/thoughtful-article"
  capture.source_name = "Example"
  capture.description = "A fictional article used to test a saved web reference."
  capture.published_at = 1.week.ago
end

idea = maya.captures.find_or_create_by!(title: "Weekend project idea") do |capture|
  capture.note = "Try a small physical prototype before buying any materials."
end

reference = maya.captures.find_or_create_by!(title: "Desk reference") do |capture|
  capture.note = "A local text attachment for testing downloads."
end

unless reference.uploads.attached?
  File.open(Rails.root.join("db/seeds/files/desk-reference.txt")) do |file|
    reference.uploads.attach(
      io: file,
      filename: "desk-reference.txt",
      content_type: "text/plain"
    )
  end
end

leo.captures.find_or_create_by!(title: "Private reading note") do |capture|
  capture.note = "This record belongs to the second fictional account."
end

reading = maya.collections.find_or_create_by!(name: "Reading list")
ideas = maya.collections.find_or_create_by!(name: "Ideas")

[
  [ reading, article, 0 ],
  [ reading, reference, 1 ],
  [ ideas, idea, 0 ]
].each do |collection, capture, position|
  collection.collection_captures.find_or_create_by!(capture: capture) do |placement|
    placement.position = position
  end
end

design = maya.tags.find_or_create_by!(name: "design")
reference_tag = maya.tags.find_or_create_by!(name: "reference")
weekend = maya.tags.find_or_create_by!(name: "weekend")

[
  [ design, article ],
  [ reference_tag, article ],
  [ reference_tag, reference ],
  [ weekend, idea ]
].each do |tag, capture|
  tag.taggings.find_or_create_by!(capture: capture)
end

puts "Seeded local development data for maya@example.test and leo@example.test (password: #{password})."
#   end
