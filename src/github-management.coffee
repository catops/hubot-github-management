# Description:
#   Allow Hubot to manage your github organization members and teams.
#
# Configuration:
#   HUBOT_GITHUB_ORG_TOKEN - (required) Github access token. See https://help.github.com/articles/creating-an-access-token-for-command-line-use/.
#   HUBOT_GITHUB_ORG_NAME - (required) Github organization name. The <org_name> in https://github.com/<org_name>/awesome-repo.
#   HUBOT_GITHUB_REPO_TEMPLATE - (optional) A git repo that will be used as a template for new repos. E.g. https://github.com/cfpb/open-source-project-template.git
#   HUBOT_GITHUB_ENTERPRISE_ENDPOINT - (optional) Set this
#
# Commands:
#   hubot github info - returns a summary of your organization
#   hubot github list (teams|repos|members) - returns a list of members, teams or repos in your organization
#   hubot github list public repos - returns a list of all public repos in your organization
#   hubot github create team <team name> - creates a team with the following name
#   hubot github create repo <repo name>/<private|public> - creates a repo with the following name, description and type (private or public)
#   hubot github add (members|repos) <members|repos> to team <team name> - adds a comma separated list of members or repos to a given team
#   hubot github remove (repos|members) <members|repos> from team <team name> - removes the repos or members from the given team
#   hubot github delete team <team name> - deletes the given team from your organization
#
# Notes:
#   Based on hubot-github by Ollie Jennings <ollie@olliejennings.co.uk>
#
# Author:
#   contolini

org = require './lib/github'
icons = require './lib/icons'
TextMessage = require('hubot').TextMessage

module.exports = (robot) ->

  return robot.logger.error "Please set a GitHub API token at HUBOT_GITHUB_ORG_TOKEN" if not process.env.HUBOT_GITHUB_ORG_TOKEN
  return robot.logger.error "Please specify a GitHub organization name at HUBOT_GITHUB_ORG_NAME" if not process.env.HUBOT_GITHUB_ORG_NAME

  org.init()

  robot.respond /(github|gh)$/i, (msg) ->
    message = """
      ```
      #{robot.name} github info - returns a summary of your organization
      #{robot.name} github list (teams|repos|members) - returns a list of members, teams or repos in your organization
      #{robot.name} github list public repos - returns a list of all public repos in your organization
      #{robot.name} github create team <team name> - creates a team with the following name
      #{robot.name} github create repo <repo name>/<private|public> - creates a repo with the following name, description and type (private or public)
      #{robot.name} github add (members|repos) <members|repos> to team <team name> - adds a comma separated list of members or repos to a given team
      #{robot.name} github remove (repos|members) <members|repos> from team <team name> - removes the repos or members from the given team
      #{robot.name} github delete team <team name> - deletes the given team from your organization
      ```
      """
    msg.send message

  robot.respond /(github|gh) info$/i, (msg) ->
    org.summary msg

  robot.respond /(github|gh) list (team|member|repo)s?/i, (msg) ->
    cmd = "#{msg.match[2]}s" if not /s$/.test(msg.match[2])
    org.list[cmd] msg

  robot.respond /(github|gh) list public (repos)/i, (msg) ->
    org.list.public msg, msg.match[2]

  robot.respond /(github|gh) create (team|repo) (\w.+)/i, (msg) ->
    unless robot.auth.isAdmin msg.envelope.user
      msg.send "#{icons.failure} Sorry, only admins can use `create` commands"
    else
      org.create[msg.match[2]] msg, msg.match[3].split('/')[0], msg.match[3].split('/')[1]

  robot.respond /(github|gh) add (member|user|repo)s? (\w.+) to team (\w.+)/i, (msg) ->
    unless robot.auth.isAdmin msg.envelope.user
      msg.send "#{icons.failure} Sorry, only admins can use `add` commands"
    else
      cmd = if /(member|user)/.test msg.match[2] then 'members' else 'repos'
      org.add[cmd] msg, msg.match[3], msg.match[4]

  robot.respond /(github|gh) remove (member|user|repo)s? (\w.+) from team (\w.+)/i, (msg) ->
    unless robot.auth.isAdmin msg.envelope.user
      msg.send "#{icons.failure} Sorry, only admins can `remove` users from teams."
    else
      cmd = if /(member|user)/.test msg.match[2] then 'members' else 'repos'
      org.remove[cmd] msg, msg.match[3], msg.match[4]

  robot.respond /(github|gh) (delete|remove) team (\w.+)/, (msg) ->
    unless robot.auth.isAdmin msg.envelope.user
      msg.send "#{icons.failure} Sorry, only admins can `delete` teams."
    else
      org.delete.team msg, msg.match[3]
