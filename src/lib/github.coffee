GitHubAPI = require 'github'
_ = require 'lodash'
ospt = require './open-source-template'
icons = require './icons'

github = new GitHubAPI version: "3.0.0", debug: false, headers: Accept: "application/vnd.github.moondragon+json"
organization = process.env.HUBOT_GITHUB_ORG_NAME
token = process.env.HUBOT_GITHUB_ORG_TOKEN

org =

  init: () ->
    github.authenticate type: "oauth", token: token

  summary: (msg) ->
    github.orgs.get org: organization, per_page: 100, (err, org) ->
      github.orgs.getMembers org: organization, per_page: 100, (memberErr, members) ->
        github.orgs.getTeams org: organization, per_page: 100, (teamErr, teams) ->
          if err or memberErr or teamErr
            msg.send "There was an error getting the details of the organization: #{organization}"
          else
            name = org.name or org.login
            location = org.location or 'unknown'
            message = """
              #{icons.team} #{name}
              - Location: #{location}
              - Created: #{org.created_at}
              - Public Repos: `#{org.public_repos}`
              - Private Repos: `#{org.total_private_repos}`
              - Total Repos: `#{org.public_repos + org.total_private_repos}`
              - Members: `#{members.length}`
              - Teams: `#{teams.length}`
              - Collaborators: #{org.collaborators}
              - Followers: #{org.followers}
              - Following: #{org.following}
              - Public Gists: #{org.public_gists}
              - Private Gists: #{org.private_gists}
              """
            msg.send message

  list:
    teams: (msg) ->
      github.orgs.getTeams org: organization, per_page: 100, (err, res) ->
        msg.send "There was an error fetching the teams for the organization: #{organization}" if err
        if err and res.length == 0
          console.error err
        message = ""
        res.forEach (team) ->
          message += "#{icons.team} #{team.name}\n"
        msg.send message

    members: (msg, teamName) ->
      github.orgs.getMembers org: organization, per_page: 100, (err, res) ->
        msg.send "There was an error fetching the memebers for the organization:#{organization}" if err
        if err and res.length == 0
          console.error err
        message = ""
        res.forEach (user) ->
          message += "#{icons.user} #{user.login}\n"
        msg.send message

    repos: (msg, repoType="all") ->
      github.repos.getFromOrg org: organization, type: repoType, per_page: 100, (err, res) ->
        msg.send "There was an error fetching all the repos for the organization: #{organization}" if err
        msg.send "#{icons.repo} #{repo.name} - #{repo.description}" for repo in res unless err and res.length == 0

  create:
    team: (msg, teamName) ->
      github.orgs.createTeam org: organization, name: teamName, permission: "push", (err, team) ->
        msg.send "There was an error and the team: `#{teamName}` was not created" if err
        msg.send "#{icons.team} `#{team.name}` was successfully created" unless err

    repo: (msg, repoName, repoStatus) ->
      github.repos.createFromOrg org: organization, name: repoName, private: repoStatus == "private", (err, repo) ->
        return msg.send "#{icons.failure} #{JSON.parse(err).message}" if err
        note = if process.env.HUBOT_GITHUB_REPO_TEMPLATE then ". Pre-populating it with template files..." else ""
        msg.send "#{icons.repo} #{repo.name} (#{icons.private}) was created#{note}" unless err or !repo.private
        msg.send "#{icons.repo} #{repo.name} (#{icons.public}) was created#{note}" unless err or repo.private
        if process.env.HUBOT_GITHUB_REPO_TEMPLATE
          ospt {user: organization, repo: repo.name, token, endpoint: 'github.com'}, (err, data) ->
            console.error err if err
            if /new branch/.test(data)
              msg.send "#{icons.success} Your repo is good-to-go at #{repo.html_url}"
            else
              msg.send "#{icons.failure} Blarg. Something when wrong when I tried to pre-populate the repo."

  add:
    repos: (msg, repoList, teamName) ->
      github.orgs.getTeams org: organization, per_page: 100, (err, res) ->
        return msg.send "There was an error adding the repos: #{repoList} to the team: #{teamName}" if err or res.length == 0
        team = _.find(res, { name: teamName })
        if team
          for repo in repoList.split ','
            github.orgs.addTeamRepo id: team.id, user: organization, repo: repo, (err, res) ->
              msg.send "#{icons.repo} `#{repo}` could not be added to the team: #{team.name}" if err
              msg.send "#{icons.repo} `#{repo}` was added to the team: #{team.name}" unless err
        else
          msg.send "#{icons.failure} Team `#{teamName}` does not exist."

    members: (msg, memberList, teamName) ->
      github.orgs.getTeams org: organization, per_page: 100, (err, res) ->
        return msg.send "There was an error adding the members: #{memberList} to the team: #{teamName}" if err or res.length == 0
        team = _.find(res, { name: teamName })
        if team
          for member in memberList.split ','
            github.orgs.addTeamMember id: team.id, user: member, (err, res) ->
              msg.send "#{icons.user} `#{member}` could not be added to the team: #{team.name}" if err
              msg.send "#{icons.user} `#{member}` was added to the team: #{team.name}" unless err
        else
          msg.send "#{icons.failure} Team `#{teamName}` does not exist."

  remove:
    repos: (msg, repoList, teamName) ->
      github.orgs.getTeams org: organization, per_page: 100, (err, res) ->
        return msg.send "There was an error removing the repos: #{repoList} from the team: #{teamName}" if err or res.length == 0
        team = _.find(res, { name: teamName })
        if team
          for repository in repoList.split ','
            github.orgs.deleteTeamRepo id: team.id, user: organization, repo: repository, (err, res) ->
              msg.send "#{icons.repo} `#{repo.name}` could not be removed from the team: #{teamName}" if err
              msg.send "#{icons.repo} `#{repo.name}` was removed from the team: #{teamName}" unless err

    members: (msg, memberList, teamName) ->
      github.orgs.getTeams org: organization, per_page: 100, (err, res) ->
        return msg.send "There was an error removing the members: #{memberList} from the team: #{teamName}" if err or res.length == 0
        team = _.find(res, { name: teamName })
        if team
          for member in memberList.split ','
            github.orgs.deleteTeamMember id: team.id, user: member, (err, res) ->
              msg.send "#{icons.user} `#{member}` could not be removed from the team: #{teamName}" if err
              msg.send "#{icons.user} `#{member}` was removed from #{icons.team} #{teamName}" unless err

  delete:
    team: (msg, teamName) ->
      github.orgs.getTeams org: organization, per_page: 100, (err, res) ->
        return msg.send "There was an error deleteing the team: #{teamName}" if err or res.length == 0
        team = _.find(res, { name: teamName })
        if team
          github.orgs.deleteTeam id: team.id, (err, res) ->
            msg.send "#{icons.team} `#{teamName}` could not be deleted" if err
            msg.send "#{icons.team} `#{teamName}` was successfully deleted" unless err

module.exports = org
