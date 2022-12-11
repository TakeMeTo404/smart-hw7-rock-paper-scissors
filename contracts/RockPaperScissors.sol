// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RockPaperScissors {
    using SafeMath for uint256;

    uint256 public gamesTotal = 0;

    enum GameStage { None, Commit, Reveal, Finished }
    enum Pick { None, Rock, Paper, Scissors }
    enum Result { None, Draw, FirstWon, SecondWon }

    struct Player {
        address payable player;

        bytes32 encryptedPick;
        bytes32 seed;
        Pick pick;

        uint256 toWithdraw;
    }

    struct Game {
        GameStage stage;
        uint256 toBet;

        Player player1;
        Player player2;

        Result result;
    }

    mapping(uint256 => Game) public games;

    event Creation(address creator, uint256 _gameId);
    event Commit(uint256 _gameId, address player, bytes32 encryptedPick);
    event Reveal(uint256 _gameId, address player, uint256 pick, bytes32 seed);
    event Withdraw(uint256 _gameId, address player);
    event StageChange(uint256 _gameId, GameStage newStage);

    modifier isPlayerOf(Game storage game) {
        require(msg.sender == game.player1.player || msg.sender == game.player2.player, "Only participant can call this function");
        _;
    }

    modifier stageEqual(Game storage game, GameStage stage) {
        require(game.stage == stage, "incorrect game stage for calling this method");
        _;
    }

    function create(uint256 toBet, address payable player1, address payable player2) public
        stageEqual(games[gamesTotal + 1], GameStage.None)
        returns (uint256) {

        gamesTotal += 1;
        uint256 gameId = gamesTotal;

        Game storage game = games[gameId];
        game.player1.player = player1;
        game.player2.player = player2;
        game.stage = GameStage.Commit;
        game.toBet = toBet;

        emit Creation(msg.sender, gameId);
        emit StageChange(gameId, GameStage.Commit);

        return gameId;
    }

    function getPlayer(Game storage game, address player) private view returns(Player storage) {
        if (game.player1.player == player) {
            return game.player1;
        }
        if (game.player2.player == player) {
            return game.player2;
        }
        revert();
    }

    function commit(uint256 _gameId, bytes32 encryptedPick) public payable
        stageEqual(games[_gameId], GameStage.Commit)
        isPlayerOf(games[_gameId]) {

        Game storage game = games[_gameId];

        require(msg.value == game.toBet, "invalid bet");

        Player storage player = getPlayer(game, msg.sender);

        require(player.encryptedPick == 0, "cannot commit twice");

        player.encryptedPick = encryptedPick;
        emit Commit(_gameId, player.player, encryptedPick);

        if (game.player1.encryptedPick != 0 && game.player2.encryptedPick != 0) {
            game.stage = GameStage.Reveal;
            emit StageChange(_gameId, GameStage.Reveal);
        }
    }

    function rockPaperScissors(Pick one, Pick two) public pure returns (Result) {
        if (one == Pick.None || two == Pick.None) {
            return Result.None;
        }
        if (
            (one == Pick.Paper && two == Pick.Rock) ||
            (one == Pick.Rock && two == Pick.Scissors) ||
            (one == Pick.Scissors && two == Pick.Paper)
        ) {
            return Result.FirstWon;
        }
        if (
            (one == Pick.Paper && two == Pick.Scissors) ||
            (one == Pick.Rock && two == Pick.Paper) ||
            (one == Pick.Scissors && two == Pick.Rock)
        ) {
            return Result.SecondWon;
        }
        return Result.Draw;
    }

    function uint256ToPick(uint256 value) private pure returns (Pick) {
        Pick pick = Pick(value);
        require(pick == Pick.Rock || pick == Pick.Paper || pick == Pick.Scissors, "invalid value");

        return pick;
    }

    function reveal(uint256 _gameId, uint256 pick, bytes32 seed) public
        isPlayerOf(games[_gameId])
        stageEqual(games[_gameId], GameStage.Reveal) {

        Game storage game = games[_gameId];

        Player storage player = getPlayer(game, msg.sender);

        bytes32 actualHash = keccak256(abi.encodePacked(pick, seed));
        bytes32 expectedHash = player.encryptedPick;

        require(actualHash == expectedHash, "invalid seed or pick");

        player.pick = uint256ToPick(pick);
        player.seed = seed;

        emit Reveal(_gameId, player.player, pick, seed);

        if (game.player1.pick != Pick.None && game.player2.pick != Pick.None) {
            game.stage = GameStage.Finished;
            emit StageChange(_gameId, GameStage.Finished);

            Result result = rockPaperScissors(game.player1.pick, game.player2.pick);
            game.result = result;

            if (result == Result.FirstWon) {
                game.player1.toWithdraw = game.toBet.mul(2);
            }
            if (result == Result.SecondWon) {
                game.player2.toWithdraw = game.toBet.mul(2);
            }
            if (result == Result.Draw) {
                game.player1.toWithdraw = game.toBet;
                game.player2.toWithdraw = game.toBet;
            }
        }
    }

    function withdraw(uint256 _gameId) public
        isPlayerOf(games[_gameId])
        stageEqual(games[_gameId], GameStage.Finished) {

        Game storage game = games[_gameId];
        Player storage player = getPlayer(game, msg.sender);

        require(player.toWithdraw != 0, "already done withdraw");

        player.player.transfer(player.toWithdraw);
        emit Withdraw(_gameId, player.player);
    }
}
