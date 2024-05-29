-- access.lua

local compose_project_name = os.getenv("COMPOSE_PROJECT_NAME") or "default_project"
local num_nodes = tonumber(os.getenv("NUM_NODES")) or 1

local servers = {}
for i = 1, num_nodes do
    local key = "te" .. i
    local value = "http://" .. compose_project_name .. "-cloudbeaver-te-" .. i .. ":8978"
    servers[key] = value
end

local cookie = ngx.var["cookie_sessionId"]

if servers[cookie] then
    ngx.var.target = servers[cookie]
else
    local keys = {}
    for key, _ in pairs(servers) do
        table.insert(keys, key)
    end
    local key = keys[math.random(#keys)]
    ngx.var.target = servers[key]
    ngx.header["Set-Cookie"] = "sessionId=" .. key .. "; Path=/; HttpOnly"
end
