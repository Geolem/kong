local Plugins = require("kong.db.dao.plugins")
local Entity = require("kong.db.schema.entity")
local Errors = require("kong.db.errors")
local helpers = require "spec.helpers"


describe("kong.db.dao.plugins", function()
  local self

  lazy_setup(function()
    assert(Entity.new(require("kong.db.schema.entities.services")))
    assert(Entity.new(require("kong.db.schema.entities.routes")))
    assert(Entity.new(require("kong.db.schema.entities.consumers")))
    local schema = assert(Entity.new(require("kong.db.schema.entities.plugins")))

    self = {
      schema = schema,
      errors = Errors.new("mock"),
      db = {},
    }
  end)

  describe("load_plugin_schemas", function()

    it("loads valid plugin schemas", function()
      local schemas, err = Plugins.load_plugin_schemas(self, {
        ["key-auth"] = true,
        ["basic-auth"] = true,
      })
      assert.is_nil(err)

      table.sort(schemas, function(a, b)
        return a.name < b.name
      end)

      assert.same({
        {
          handler = { _name = "basic-auth" },
          name = "basic-auth",
        },
        {
          handler = { _name = "key-auth" },
          name = "key-auth",
        },
      }, schemas)
    end)

    it("reports invalid plugin schemas", function()
      local s = spy.on(kong.log, "warn")

      local schemas, err = Plugins.load_plugin_schemas(self, {
        ["key-auth"] = true,
        ["invalid-schema"] = true,
      })

      assert.spy(s).was_called(1)
      mock.revert(kong.log)

      table.sort(schemas, function(a, b)
        return a.name < b.name
      end)

      assert.is_nil(err)
      assert.same({
        {
          handler = { _name = "invalid-schema" },
          name = "invalid-schema",
        },
        {
          handler = { _name = "key-auth" },
          name = "key-auth",
        },
      }, schemas)
    end)

  end)


  for _, strategy in helpers.each_strategy() do
    local bp, db, route, service

    before_each(function()
      bp, db = helpers.get_db_utils(strategy, {
        "routes",
        "services",
        "plugins",
      })
      service = bp.services:insert()
      route = bp.routes:insert({ protocols = { "tcp" },
                                 sources = { { ip = "127.0.0.1" } },
                               })

    end)


    describe("protocols matching route [#" .. strategy ..  "]", function()
      it("returns an error when inserting mismatched plugins", function()
        local plugin, _, err_t = db.plugins:insert({ name = "key-auth",
                                                     protocols = { "http" },
                                                     route = { id = route.id },
                                                   })
        assert.is_nil(plugin)
        assert.equals(err_t.fields.protocols, "Plugin protocols must match the associated route's protocols")

        local plugin, _, err_t = db.plugins:insert({ name = "key-auth",
                                                     protocols = { "tcp" },
                                                     service = { id = service.id },
                                                   })
        assert.is_nil(plugin)
        assert.equals(err_t.fields.protocols,
                      "Plugin protocols must match at least one of the service's route's protocols")
      end)

      it("returns an error when updating mismatched plugins", function()
        local plugin = db.plugins:insert({ name = "key-auth",
                                           protocols = { "http" },
                                         })
        assert.truthy(plugin)

        local p, _, err_t = db.plugins:update({ id = plugin.id },
                                              { route = { id = route.id } })
        assert.is_nil(p)
        assert.equals(err_t.fields.protocols, "Plugin protocols must match the associated route's protocols")


        local p, _, err_t = db.plugins:update({ id = plugin.id },
                                              { service = { id = service.id } })
        assert.is_nil(p)
        assert.equals(err_t.fields.protocols,
                      "Plugin protocols must match at least one of the service's route's protocols")
      end)

      it("returns an error when upserting mismatched plugins", function()
        local plugin = db.plugins:insert({ name = "key-auth",
                                           protocols = { "http" },
                                         })
        assert.truthy(plugin)

        local p, _, err_t = db.plugins:upsert({ id = plugin.id },
                                              { route = { id = route.id } })
        assert.is_nil(p)
        assert.equals(err_t.fields.protocols, "Plugin protocols must match the associated route's protocols")


        local p, _, err_t = db.plugins:upsert({ id = plugin.id },
                                              { service = { id = service.id } })
        assert.is_nil(p)
        assert.equals(err_t.fields.protocols,
                      "Plugin protocols must match at least one of the service's route's protocols")
      end)


    end)
  end
end)
