challengeUtils = require './challengeUtils'


exports.challenge = ->
  shouldFindTreasure = Math.floor(Math.random() * 2) == 1
  shouldMeetPirate = Math.floor(Math.random() * 2) == 1
  getChallenge(shouldFindTreasure, shouldMeetPirate)

getChallenge = (shouldFindTreasure, shouldMeetPirate) ->

  startX = Math.floor(Math.random() * 20) + 10
  startY = Math.floor(Math.random() * 20) + 10

  instructions = challengeUtils.getInstructions(Math.floor(Math.random() * 10) + 10)
  treasureCoordinate = challengeUtils.calculateItemCoordinate(instructions, shouldFindTreasure, [startX, startY])

  midPosition = challengeUtils.calculateEndPosition(instructions, [startX, startY])
  furtherInstructions = challengeUtils.getInstructions(Math.floor(Math.random() * 10) + 10)

  pirateCoordinate = challengeUtils.calculateItemCoordinate(furtherInstructions, shouldMeetPirate, midPosition)
  endPosition = challengeUtils.calculateEndPosition(furtherInstructions, midPosition)

  question:
    startX: startX
    startY: startY
    treasureX: treasureCoordinate[0]
    treasureY: treasureCoordinate[1]
    pirateX: pirateCoordinate[0]
    pirateY: pirateCoordinate[1]
    instructions: instructions.concat(furtherInstructions).join('')
  answer:
    endX: endPosition[0]
    endY: endPosition[1]
    treasureFound: shouldFindTreasure
    treasureStolen: shouldFindTreasure && shouldMeetPirate

exports.getChallenge = getChallenge
