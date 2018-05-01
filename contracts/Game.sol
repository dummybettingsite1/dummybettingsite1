pragma solidity ^0.4.18;

contract Game {

  event GameFinished(
    string _matchName
  );

  event BetPlaced(
    address _player,
    string _matchName
  );

  enum MatchEnd {HOME,DRAW,AWAY,NON}

  struct Bet {
    address player;
    MatchEnd out;
  }

  struct Duel {
    uint id;
    Bet first;
    Bet second;
  }

  struct Match {
    uint id;
    string name;
    string stadium;
    string date;
    MatchEnd result;
    uint duelCounter;

    mapping (uint => Duel) duels;
  }

  address owner;
  Match usedMatch;
  Duel usedDuel;
  uint matchCounter;

  mapping (uint => Match) public matches;

  function Game() public {
    owner = msg.sender;
    addMatch("Argentine - Croatia", "Luzshnyiki Stadium", "2018.06.25");
    addMatch("Brazil - Germany", "Kazan Arena", "2018.06.26");
    addMatch("Spain - Iran", "Luzshnyiki Stadium", "2018.06.27");
  }

  function addMatch(string _name, string _date, string _stadium) public {
    require(msg.sender == owner);
    matchCounter++;
    matches[matchCounter] = Match(matchCounter, _name, _stadium, _date, MatchEnd.NON, 0);
    usedMatch = matches[matchCounter];
    usedMatch.duels[0] = Duel(usedMatch.duelCounter, Bet(0x0, MatchEnd.NON), Bet(0x0, MatchEnd.NON));
  }

  function setMatchResult(uint _id, MatchEnd _result) payable public {
    require(msg.sender == owner);

    usedMatch = matches[_id];

    usedMatch.result = _result;
    matches[_id].result = _result;
    for (uint i = 0; i <= usedMatch.duelCounter; i++) {
      if ((usedMatch.duels[i].first.out == usedMatch.result) && (usedMatch.duels[i].second.out == usedMatch.result)) {
        usedMatch.duels[i].first.player.transfer(msg.value/2);
        usedMatch.duels[i].second.player.transfer(msg.value/2);
      }
      if ((usedMatch.duels[i].first.out != usedMatch.result) && (usedMatch.duels[i].second.out != usedMatch.result)) {
        usedMatch.duels[i].first.player.transfer(msg.value/2);
        usedMatch.duels[i].second.player.transfer(msg.value/2);
      }
      if ((usedMatch.duels[i].first.out == usedMatch.result) && (usedMatch.duels[i].second.out != usedMatch.result)) {
        usedMatch.duels[i].first.player.transfer(msg.value);
      }
      if ((usedMatch.duels[i].first.out != usedMatch.result) && (usedMatch.duels[i].second.out == usedMatch.result)) {
        usedMatch.duels[i].second.player.transfer(msg.value);
      }
    }

    GameFinished(usedMatch.name);
  }

  function getMatchCount() public view returns (uint) {
    return matchCounter;
  }

  function getPlayable() public view returns (uint[]) {
    uint[] memory matchIds = new uint[](matchCounter);

    uint c = 0;

    for (uint i = 1; i <= matchCounter; i++) {
      if (matches[i].result == MatchEnd.NON) {
        matchIds[c] = matches[i].id;
        c++;
      }
    }

    uint[] memory toReturn = new uint[](c);
    for (uint j = 0; j < c; j++) {
      toReturn[j] = matchIds[j];
    }

    return toReturn;
  }

  function placeBet(uint _id, MatchEnd _out) payable public {
    usedMatch = matches[_id];
    usedDuel = usedMatch.duels[usedMatch.duelCounter];

    if (usedDuel.first.player == 0x0) {
      usedMatch.duels[usedMatch.duelCounter].first.player = msg.sender;
      usedMatch.duels[usedMatch.duelCounter].first.out = _out;
    } else {
      if (usedDuel.second.player == 0x0 && usedDuel.first.player != msg.sender) {
        usedMatch.duels[usedMatch.duelCounter].second.player = msg.sender;
        usedMatch.duels[usedMatch.duelCounter].second.out = _out;
      } else {
        usedMatch.duelCounter++;
        usedMatch.duels[usedMatch.duelCounter] = Duel(usedMatch.duelCounter, Bet(0x0, MatchEnd.NON), Bet(0x0, MatchEnd.NON));
        usedMatch.duels[usedMatch.duelCounter].first.player = msg.sender;
        usedMatch.duels[usedMatch.duelCounter].first.out = _out;
      }
    }

    owner.transfer(msg.value);

    BetPlaced(msg.sender, usedMatch.name);
  }

}
