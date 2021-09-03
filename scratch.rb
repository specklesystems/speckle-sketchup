require "net/http"

require "json"

require "uri"

server = "https://latest.speckle.dev"

token = "1dc2e3330a56371dc9011e5bed406264c9e65dd355"

limit = 20
streams_list = "
query User {
  user {
    id
    email
    name
    bio
    company
    avatar
    verified
    profiles
    role
    streams(limit: #{limit}) {
      totalCount
      cursor
      items {
        id
        name
        description
        isPublic
        createdAt
        updatedAt
        collaborators {
          id
          name
          role
        }
      }
    }
  }
}
"

endpoint = URI("#{server}/graphql")

res =
  ::Net::HTTP.start(endpoint.host, endpoint.port, use_ssl: true) do |http|
    req = ::Net::HTTP::Post.new(endpoint)
    req["Content-Type"] = "application/json"
    req["Authorization"] = "Bearer #{token}"
    # The body needs to be a JSON string.
    req.body = ::JSON[{ query: streams_list }]
    puts(req.body)
    http.request(req)
  end

streams = ::JSON.parse(res.body)["data"]["user"]["streams"]["items"]
puts(streams)
