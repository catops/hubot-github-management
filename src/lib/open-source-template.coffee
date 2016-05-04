tmp = require 'tmp'
{exec} = require 'child_process'

templateRepo = process.env.HUBOT_GITHUB_REPO_TEMPLATE || 'https://github.com/cfpb/open-source-project-template.git'

init = ({user, repo, token, endpoint}, cb) ->
  tmp.dir {unsafeCleanup: true}, (err, path, cleanup) ->
    throw err if err
    exec "git init", {cwd: path}, (err) ->
      console.error err if err
      exec "git pull #{templateRepo}", {cwd: path}, (err) ->
        console.error err if err
        exec "git push https://#{token}@#{endpoint}/#{user}/#{repo}.git master", {cwd: path}, (err, stdout, stderr) ->
          cleanup()
          return cb(err) if err
          cb null, stdout or stderr
    return

module.exports = init
