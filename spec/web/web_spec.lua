local utils = require "apenode.utils"
local cjson = require "cjson"
local kWebURL = "http://localhost:8001/"

describe("Web API #web", function()

  describe("/", function()
    it("should return the apenode version and a welcome message", function()
      local response, status, headers = utils.get(kWebURL)
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.truthy(body.version)
      assert.truthy(body.tagline)
    end)
  end)

  describe("APIs", function()
    it("get all", function()
      local response, status, headers = utils.get(kWebURL .. "/apis/")
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.truthy(body.data)
      assert.truthy(body.total)
      assert.are.equal(3, body.total)
      assert.are.equal(3, table.getn(body.data))
    end)
    it("create with invalid params", function()
      local response, status, headers = utils.post(kWebURL .. "/apis/", {})
      assert.are.equal(400, status)
      assert.are.equal('["public_dns must be provided","Invalid target_url","Invalid authentication_type","authentication_key_names must be provided"]', response)
    end)
  end)

end)
