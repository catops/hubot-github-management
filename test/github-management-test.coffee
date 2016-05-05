chai = require 'chai'
sinon = require 'sinon'
_ = require 'lodash'
expect = chai.expect
helper = require 'hubot-mock-adapter-helper'
TextMessage = require('hubot/src/message').TextMessage
icons = require '../src/lib/icons'

chai.use require 'sinon-chai'

seed = Date.now()

fixtures =
  user: 'mistersandwichwoman'
  team: 'team' + seed
  repo: 'repo' + seed

class Helper
  constructor: (@robot, @adapter, @user)->

  sendMessage: (done, message, callback)->
    if typeof done == 'string'
      callback = message or ->
      message = done
      done = ->
    @sendMessageHubot(@user, message, callback, done, 'send')

  replyMessage: (done, message, callback)->
    if typeof done == 'string'
      callback = message
      message = done
      done = ->
    @sendMessageHubot(@user, message, callback, done, 'reply')

  sendMessageHubot: (user, message, callback, done, event) ->
    done = _.once done
    @adapter.on event, (envelop, string) ->
      try
        callback(string)
        done()
      catch e
        done(e)
    @adapter.receive new TextMessage(user, message)

describe 'github-management', ->
  this.timeout 5000
  {robot, user, adapter} = {}
  messageHelper = null

  beforeEach (done)->
    delete process.env.HUBOT_GITHUB_REPO_TEMPLATE
    helper.setupRobot (ret) ->
      process.setMaxListeners(0)
      {robot, user, adapter} = ret
      messageHelper = new Helper(robot, adapter, user)
      process.env.HUBOT_AUTH_ADMIN = user['id']
      messageHelper.robot.auth = isAdmin: ->
        return process.env.HUBOT_AUTH_ADMIN.split(',').indexOf(user['id']) > -1
      do done

  afterEach ->
    robot.shutdown()

  beforeEach ->
    require('../src/github-management')(robot)

  describe 'teams', ->
    it "successfully lists teams", (done) ->
      messageHelper.sendMessage done, 'hubot github list teams', (result) ->
        expect(result[0]).to.contain("#{icons.team}")

    it "successfully creates teams", (done) ->
      messageHelper.sendMessage done, "hubot github create team #{fixtures.team}", (result) ->
        expect(result[0]).to.contain("`#{fixtures.team}` was successfully created")

    it "fails to delete team if you're not an admin", (done) ->
      process.env.HUBOT_AUTH_ADMIN = []
      messageHelper.sendMessage done, "hubot github delete team #{fixtures.team}", (result) ->
        expect(result[0]).to.contain("Sorry, only admins")

    it "successfully deletes teams", (done) ->
      messageHelper.sendMessage done, "hubot github delete team #{fixtures.team}", (result) ->
        expect(result[0]).to.contain("`#{fixtures.team}` was successfully deleted")

  describe 'members', ->
    before (done) ->
      messageHelper.sendMessage "hubot github create team #{fixtures.team}"
      do done

    after ->
      messageHelper.sendMessage "hubot github delete team #{fixtures.team}"

    it "successfully lists members", (done) ->
      messageHelper.sendMessage done, 'hubot github list members', (result) ->
        expect(result[0]).to.contain("#{icons.user}")

    it "successfully adds member to team", (done) ->
      messageHelper.sendMessage done, "hubot github add members #{fixtures.user} to team #{fixtures.team}", (result) ->
        expect(result[0]).to.contain("#{icons.user}")

    it "fails to remove member if you're not an admin", (done) ->
      process.env.HUBOT_AUTH_ADMIN = []
      messageHelper.sendMessage done, "hubot github remove members #{fixtures.user} from team #{fixtures.team}", (result) ->
        expect(result[0]).to.contain("Sorry, only admins")

    it "successfully remove member", (done) ->
      messageHelper.sendMessage done, "hubot github remove members #{fixtures.user} from team #{fixtures.team}", (result) ->
        expect(result[0]).to.contain("was removed from")

  describe 'repos', ->
    before (done) ->
      messageHelper.sendMessage "hubot github create team #{fixtures.team}"
      do done

    after ->
      messageHelper.sendMessage "hubot github delete team #{fixtures.team}"

    it "successfully lists repos", (done) ->
      messageHelper.sendMessage done, 'hubot github list repos', (result) ->
        expect(result[0]).to.contain("#{icons.repo}")

    it "successfully creates a repo", (done) ->
      messageHelper.sendMessage done, "hubot github create repo #{fixtures.repo}", (result) ->
        expect(result[0]).to.contain("#{icons.repo}")
