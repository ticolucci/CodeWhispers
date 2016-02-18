connection = require './connection'
round = require './round'
checker = require '../challenges/checker'

io = null
exports.initIo = (_io) ->
  io = _io

exports.question = (req, res) ->
  context = {}
  connection.open()
  .then (client) ->
    context.client = client
    round.getRound client
  .then (round) ->
    context.round = round
    challenge = generateQandA(round)
    challenge.team = req.params['team']
    context.challenge = challenge
    context.collection = context.client.collection 'challenge'
    context.collection.findOne {team: challenge.team}
  .then (oldChallenge) ->
    if oldChallenge
      context.challenge._id = oldChallenge._id
      context.challenge.count = oldChallenge.count + 1 if oldChallenge.result && oldChallenge.count < requiredAttempts(context.round) && oldChallenge.round == context.round
    context.collection.save context.challenge, {safe:true}
  .then ->
    io.emit 'result', {team: context.challenge.team, round: context.round, status: 'working'} if context.challenge.count == 0
    res.json context.challenge.question
  .catch (error) ->
    console.log error
    res.status(500).json(error)
  .finally ->
    context.client.close() if context.client


exports.answer = (req, res) ->
  team = req.params['team']
  context = {}
  connection.open()
  .then (client) ->
    context.client = client
    round.getRound client
  .then (round) ->
    context.round = round
    context.collection = context.client.collection 'challenge'
    context.collection.findOne {team: team}
  .then (doc) ->
    doc.result = correct(req.body, doc.answer, context.round)
    context.doc = doc
    context.collection.save doc, {safe:true}
  .then ->
    setResult context.client, context.round, team, context.doc.result, context.doc.count
  .then (status) ->
    io.emit 'result', {team: team, round: context.round, status: status} unless status == 'working'
    if context.doc.result
      if context.doc.count >= requiredAttempts(context.round)
        res.send(200, "OK")
      else
        res.redirect(303, "/routes/challenge/#{team}")
    else
      res.status(418).json({yourAnswer: req.body, correctAnswer: context.doc.answer})
  .catch (error) ->
    console.log error
    res.status(500).json(error)
  .finally ->
    context.client.close() if context.client

setResult = (client, round, team, gotItRight, count) ->
  collection = client.collection 'branches'
  status = null
  collection.findOne {name: team}
  .then (doc) ->
    unless gotItRight
      status = 'failure'
    else if count == requiredAttempts(round)
      status = 'success'
    else
      status = 'working'
    doc[round] = status
    collection.save doc, {safe:true}
  .then ->
    status

requiredAttempts = (round) ->
  return 2 if round == 0
  return round * 5

correct = (reqBody, answer, round) ->
  checker.check(answer, reqBody)

generateQandA = (round) ->
  challenge = require("../challenges/challenge#{round}").challenge()
  challenge.round = round
  challenge.count = 0
  challenge.result = false
  return challenge
