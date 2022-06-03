# COMP1100 Assignment 3

In this assignment, you will develop a [software
agent](https://en.wikipedia.org/wiki/Software_agent) or *AI bot* that
plays [Fanorona](https://en.wikipedia.org/wiki/Fanorona). We have
implemented the rules of the game for you. Your task is to decide
how is best to play.



## Overview of the Game

Fanorona is a two-player strategy boardgame from Madagascar.
The version we will (roughly) be playing, Fanorona-Tsivy, is played on a 
$$9\times 5$$ board with the following starting configuration: 

![Initial State](initial_board.png){:.w300px}

Tiles are placed on vertices and may move along any edge from
a given vertex. Note that on this style of board, sometimes known
as an [Alquerque](https://en.wikipedia.org/wiki/Alquerque) board,
diagonals are sometimes (but not always) available. 

The player with light coloured tiles moves first, and moves are split into three
main categories:

1. Capturing moves.

A player may capture a contiguous line of opponent pieces
by **either** approaching **or** withdrawing from such a contiguous line. 

Such a move is classified as either an `Approach` or a `Withdrawal`, and defined
by the `Location`s the piece moves from and to.

At the start of a *turn*, a *player* must make a capturing move if it is possible to do so.
After making such a move, lets call the piece that moved the *Captor*. If it is possible
for the *Captor* to move again, provided it visits no *Location* more than once in a 
*turn*, the *player* may make another move. If, after a *turn* has started,
the *Captor* cannot make a capture, then the *turn* is over and it is the *other player*'s
turn.

2. Pass [COMP1130 Students Only]

A player may terminate a *turn* early by making a 
Pass. Note that a player cannot Pass unless a *turn* has already started (i.e., there is a Captor).

Note that Pass moves will not appear in the list of legal moves. It is up to you
to decide when they should be considered, but they must be considered (and can only
be called when legal to do so).

COMP1100 students use a slightly simplified version of the game where *turn*s of
capturing sequences must be completed, not truncated by passing.

3. Paika.

If, at the start of a *turn* there is no possible *capturing move*, then
you may make a *Paika* move, moving any of your pieces to an adjacent empty vertex.
this also concludes the *turn*.

The game is over if either a board position is repeated (this can only occur after
a sequence of *Paika* moves) --- in this case ending in a draw --- or when one player
is not able to make a move (typically because they have used all their pieces). The
player who made the last move is then the winner, and the player who cannot move the loser.

The game will also end in a draw if there have been more than 20 consecutive Paika moves,
but this should be very rare.

## Overview of the Repository

Most of your code will be written in `src/AI.hs`, but you will also
need to write tests in `src/AITests.hs`.

### Other Files

* `src/Fanorona.hs` implements the rules of Fanorona. You should read
  through this file and familiarise yourself with the data
  declarations and the type signatures of the functions in it, as you
  will use some of these to analyse the game states. You do not need
  to understand how the functions in this file works in detail.

* `src/FanoronaTests.hs` implements some unit tests for the game. You
  are welcome to read through it.

* `src/AITests.hs` is an empty file for you to write tests for your
  agent.

* `src/Testing.hs` is a simple test framework similar to the one in
  Assignment 2. However, it has been extended so that you can group
  related tests together for clarity.

* `src/Dragons` contains all the other code that makes the framework
  go. You do not need to read or understand anything in this
  directory. Here be dragons! (On medieval maps they drew pictures of
  dragons or sea monsters over uncharted areas.) The code in those
  files is beyond the areas of Haskell which this course explores.

* `Setup.hs` tells cabal that this is a normal package with no unusual
  build steps. Some complex packages (that we will not see in this
  course) need to put more complex code here. You are not required to
  understand it.

* `comp1100-assignment3.cabal` tells the cabal build tool how to build
  your assignment. We will discuss how to use `cabal` below.

* `.ghcid` tells the `ghcid` tool which command to run, which is what
  supplies VSCodium with error highlighting that automatically updates
  when you save a file.

* `.gitignore` tells `git` which files it should not put into version
  control. These are often generated files, so it doesn't make sense
  to place them under version control.

## Overview of Cabal

As before, we are using the `cabal` tool to build the assignment
code. The commands provided are very similar to last time:

* `cabal v2-build`: Compile your assignment.

* `cabal v2-run game`: Build your assignment (if necessary), and run
  the test program. We discuss the test program in detail below, as
  there are a number of ways to launch it.

* `cabal repl comp1100-assignment3`: Run the GHCi interpreter over
  your project so you can test functions interactively.

* `cabal v2-test`: Build and run the tests. This assignment is set up
   to run a unit test suite, and as with Assignment 2 you will be
   writing tests. The unit tests will abort on the first failure, or
   the first call to a function that is `undefined`.

* `cabal v2-haddock`: Generate documentation in HTML format, which you
  can read with a web browser. This might be a nice way to read a
  summary of the game module, but it also documents the `Dragons`
  modules which you can safely ignore.

{:.msg-info}  
You should execute these cabal commands in the **top-level directory**
of your project: `comp1100-assignment3` (i.e., the directory you are
in when you launch a terminal from VSCodium).

## Overview of the Test Program

To run the test program, you need to provide it with command line
arguments that tell it who is playing. This command will let you play
against the current `"default"` AI bot.
Before you replace this with your own bot, the default will be
`firstLegalMove` playing with COMP1100 rules:

```
cabal v2-run game -- --p1 human --p2 ai
```

using `ai` to get the default ai is part of how we mark
your assignment, so it is **vital** that you update your
default bot to be whatever you want to be marked!

To play with a differently named AI, say, `"greedy`, use:

```
cabal v2-run game -- --p1 human --p2 ai:greedy
```

In general, the command to run the game looks like this:

```
cabal v2-run game -- ARGS
```

Replace `ARGS` with a collection of arguments from the following list:

* `--comp1130`: Run the COMP1130 version of the game (with `Pass` enabled).

* `--timeout DURATION`: Change the amount of time (in decimal seconds)
  that AI functions are given to think of a move (default = `4.0`).
  You may want to set this to a smaller number when testing your program,
  so that things run faster.

* `--height LENGTH` and `--width LENGTH` - Alter the size of the board
 to the given value (rounded up to the nearest odd number - Fanorona only makes sense on
 odd size boards). The default values are 9 and 5 respectively, and your implementations
 will only be tested on that size. 
 
 Your AI does not need to work for differently sized boards, but you may want to test it
 on simpler boards if it does! 

* `--debug-lookahead`: When an AI is done thinking, print out how many
  moves ahead it considered, and the candidate move it came up with at
  each level of lookahead. The first item in the printed list is the
  move it came up with at lookahead 1, the second item is the move it
  came up with at lookahead 2, and so on.

* `--ui codeworld`: Show the game using CodeWorld. This is the default
  user interface. Use your web browser to play the game, as in
  previous assignments. Unlike the codeworld programs in previous
  assignments, you must terminate the program with `Ctrl-C` and
  restart it if you want to restart your game.

* `--ui text`: Show the game in the terminal.

* `--ui json`: Run a non-interactive game (i.e., AI vs. AI, or AI *vs*
  network), and output a report of the game in JSON format. You
  probably won't have a use for this, but it's documented here for
  completeness.

* `--host PORT`: Listen for a network connection on `PORT`. You only
  need this for network play (see below).

* `--connect HOST:PORT`: Connect to someone else's game. You only need
  this for network play (see below).

* `--p1 PLAYER`: Specify the white player. Required.

* `--p2 PLAYER`: Specify the black player. Required.

The `PLAYER` parameters describe who is playing, and can take one of
the following forms:

| **Format**  | **Effect**                                                  |
|-------------|-------------------------------------------------------------|
| `human`     | Ask the person at the computer for moves.                   |
| `ai`        | Ask the `"default"` AI for moves.                           |
| `ai:AINAME` | Ask a specific AI for moves (example: `ai:firstLegalMove`). |
| `network`   | Wait for a move from the network.                           |

### Network Play

{:.msg-warn}  
Network play is provided in the hope that it will be useful, but we
are unable to provide support for this feature, or diagnose problems
related to tunnelling network connections between computers.

The assignment framework supports network play, so that you can test
agents against each other without sharing code. One machine must
_host_ the game, and the other machine must _connect_ to the game. In
the example below, machine A hosts a game on port 5000 with the agent
`crashOverride` as player 1, then machine B connects to the game,
providing the AI `chinook` as player 2:

```
# On Machine A:
cabal v2-run game -- --host 5000 --p1 ai:crashOverride --p2 network

# On Machine B (you'll need Machine A's external IP address somehow):
cabal v2-run game -- --connect 198.51.100.66:5000 --p1 network --p2 ai:chinook
```

{:.msg-info}  
Under the bonnet, the network code makes a single TCP connection, and
moves are sent over the network in JSON. You will need to set up your
modem/router to forward connections to the machine running your
assignment. A service like [ngrok](https://ngrok.com/) may help, but
as previously mentioned we are unable to provide any support for this
feature.


## Main Task: Fanorona AI

Implement an AI (of type `AIFunc`, defined in `src/AI.hs`). There is a
list called `ais` in that file, and we will mark the AI you call
`"default"` in that list. This list is also where the framework looks
when it tries to load an AI by name.

We will test your AI's performance by comparing it to implementations
written by course staff, using a variety of standard approaches. Its
performance against these AIs will form a large part of the marks for
this Task.

{:.msg-warn}  
It is **vital** that you indicate one AI as `"default"`, otherwise we
will not know which one to mark. TO indicate an AI as `"default"`,
you must have a `(String, AIFunc)` pair in the `ais` list of AIs
in `src/AI.hs` where the `String` is **precisely** `"default"`. 


## Understanding the `AIFunc` Type

The `AIFunc` type has two constructors, depending on whether you are
implementing a simple AI that looks only at the current state, or a
more complicated AI that performs look-ahead.

The `NoLookahead` constructor takes as its argument a function of type
`GameState -> Move`. That is, the function you provide should look at
the current state of the game and return the move to play. This
constructor is intended for very simple AIs that do not look ahead in
the game tree. As such, this function should never run for more than
a moment at a time, but nevertheless, it is also subject to the timeout
of 4 seconds.

The `WithLookahead` constructor takes as its argument a function of
type `GameState -> Int -> Move`. The `Int` parameter may be used to
represent how many steps you should try to look ahead in the game
tree. The assignment framework will call your function over and over,
with look-ahead `1`, then `2`, then `3`, etc., until it runs out of
time. The framework will take the result of the most recent successful
function call as your AI's best move. If your AI does not return a
move in time, the program will stop with an error.


### Getting Started

This is a very open-ended task, and it will probably help if you build
up your solution a little at a time. We suggest some approaches below.

Your AI should inspect the `Turn` within the `Game` to see whose turn
it is. You may call `error` if the `Turn` is `GameOver` - your AI
should never be called on a finished game. Your AI can then use the
`Player` value and `otherPlayer` function to work out how to evaluate
the board.

When you call `legalMoves` on a given `GameState`, it will never return
a list containing `Pass`, even when such a move is legal.
COMP1130 students are expected to consider passing moves in your implementation,
so you must determine when passing moves should be considered explicitly. 

{:.msg-info}  
You may also assume that we will only ever call your AI if there is a
legal move it can make. In particular, this means that we will not
deduct marks for assuming that a list of legal moves is non-empty
(e.g., you used the `head` function). Note that gratuitous use of
`head` and `tail` is still poor style. Note that, in general, you cannot
make this assumption about `GameStates` you have generated
within your AI function.

### First Legal Move

The simplest AI you can build is one that makes the first legal move
it can. We have provided this for you, so you can see what a simple
`AI` looks like.

### Interlude: Heuristics

Heuristic functions are discussed in the lecture on game trees.  We
expect the quality of your heuristic function---how accurately it
scores game states---to have a large impact on how well your AI
performs.

### Greedy Strategy

"Greedy strategies" are the class of strategies that make moves that
provide the greatest _immediate_ advantage. In the context of this
game, it means always making the move that will give it the greatest
increase in heuristic. Try writing a simple heuristic and a greedy
strategy, and see whether it beats your "first legal move" AI. Bear in
mind that in a game like this `firstLegalMove` will not play terribly,
as it still must capture when given the opportunity.

### Considering Whole Turns

In this implementation of Fanorona, making a *move* does not necessarily
mark the end of your *turn*. In cases where a *turn* may contain multiple *moves*,
you may want to consider how to select the best *move* in terms of your *turn* as a
whole.

Abstracting multiple *moves* into a single *turn* may also help with conceptualising
game trees (discussed below), as a game tree of *move*s may have differing *turn*s at
the same depth. In a game tree of *turns* you can always be sure that the *player*
alternates at every level in the tree.

### Interlude: Game Trees

To make your AI smarter, it is a good idea for it to look into the
future and consider responses to its moves, its responses to those
responses, and so on. The lecture on game trees may help you here.


### Minimax

Greedy strategies can often miss opportunities that need some
planning, and get tricked into silly traps by smarter opponents. The
Minimax Algorithm was discussed in the lecture on game trees and will
likely give better performance than a greedy strategy.

### Pruning

Once you have Minimax working, you may find that your AI exploring a
number of options that cannot possibly influence the result. Cutting
off branches of the search space early is called _pruning_, and one
effective method of pruning is called **alpha-beta pruning** as
discussed in lectures. Good pruning may allow your search to explore
deeper within the time limit it has to make its move.

### Other Hints

* There are four main ways your AI can be made smarter:

  - Look-ahead: If your function runs efficiently, it can see further
    into the future before it runs out of time. The more moves into
    the future it looks, the more likely it will find good moves that
    are not immediately obvious. Example: at 1 level of look-ahead, a
    move may let you capture a lot of pieces, but at deeper look-ahead
    you might see that it leaves you open to a large counter-capture.

  - Heuristic: You will not have time to look all the way to the end
    of every possible game. Your heuristic function guesses how good a
    `Game` is for each player. If your heuristic is accurate, it will
    correctly identify strong and weak states.

  - Search Strategy: This determines how your AI decides which
    heuristic state to aim for. Greedy strategies look for the best
    state they can (according to the heuristic) and move towards that
    state. More sophisticated strategies like Minimax consider the
    opponent's moves when planning.

  - Pruning: if you can discard parts of the game tree without
    considering them in detail, you can process game trees faster and
    achieve a deeper look-ahead in the allotted running
    time. Alpha-beta pruning is one example; there are others.

* Choosing a good heuristic function is very important, as it gives
  your AI a way to value its position that is smarter than just
  looking at current score. Perhaps you might find that some squares
  are more valuable than others, when it comes to winning games, and
  so your AI should value them more highly.

* Do not try to do everything at once. This does not work in
  production code and often does not work in assignment code
  either. Get something working, then take your improved understanding
  of the problem to the more complex algorithms.

* As you refine your bots, test them against each other to see whether
  your changes are actually an improvement.


