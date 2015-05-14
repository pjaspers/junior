# Junior

[![Build Status](https://travis-ci.org/pjaspers/junior.svg?branch=master)](https://travis-ci.org/pjaspers/junior)

A small sinatra app that lets people place a bet on our upcoming baby.

## Setting up Shack

Pushing the sha using the Heroku API.

It turns out you can't use the Heroku toolbelt in a build (since it isn't installed, and even if it was installed, it wouldn't have access to your Heroku since it doesn't have your config).

So now I'm using a curl (C.R.E.A.M. [0]) to issue a request to the Heroku API using a secured environment variable [1] (because you can't access the api key that's set in the deploy section of .travis.yml. [2]

In order for Travis to have access to the Heroku Auth token, it's needed to add it to the `.travis.yml` file.

`travis encrypt $(heroku auth:token) --add deploy.api_key`
`travis encrypt HEROKU_API_KEY=$(heroku auth:token) --add env.global`

(Once for deploying, once for setting the sha using the API)

[0] The Wu-Tang were almost right, it's not cash but curl that rules everything around me
[1] http://docs.travis-ci.com/user/environment-variables/
[2] https://twitter.com/travisci/status/553243976619524096
