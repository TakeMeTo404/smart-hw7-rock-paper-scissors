import {Signer} from "ethers";
import {RockPaperScissors} from "../typechain-types";

const { expect } = require("chai");
const { ethers } = require("hardhat");

const pick1 = 1; // rock
const seed1 = "f".repeat(32);
const encryptedPick = ethers.utils.solidityKeccak256(
    ethers.utils.solidityPack(
        ["uint256", "bytes32"],
        [pick1, seed1]
    )
);

describe("InterContract", function(){
    let rps: RockPaperScissors;
    let account: Signer;
    let opponent: Signer;

    beforeEach(async () => {
        [account, opponent] = await ethers.getSigners();

        const rpsFactory = await ethers.getContractFactory("RockPaperScissors");
        rps = await rpsFactory.deploy();
        await rps.deployed();
    });

    describe("Rps tests", () => {
        it("should create game", async () => {
            const gamesTotalBefore = await rps.connect(account).gamesTotal();
            expect(gamesTotalBefore).to.equal(0);

            const gameId = await rps.connect(account).create(
                ethers.utils.parseEther("1"),
                await account.getAddress(),
                await opponent.getAddress()
            );

            const gamesTotalAfter = await rps.gamesTotal();
            expect(gamesTotalAfter).to.equal(1);
        });

        it("commit for participant", async () => {
            const gamesTotalBefore = await rps.connect(account).gamesTotal();
            expect(gamesTotalBefore).to.equal(0);

            const gameId = await rps.connect(account).create(
                ethers.utils.parseEther("1"),
                await account.getAddress(),
                await opponent.getAddress()
            );

            expect(() => rps.connect(account).commit(1, encryptedPick))
                .to.not.throw()
        });

        it("commit and correct reveal", async () => {
            const gamesTotalBefore = await rps.connect(account).gamesTotal();
            expect(gamesTotalBefore).to.equal(0);

            const gameId = await rps.connect(account).create(
                ethers.utils.parseEther("1"),
                await account.getAddress(),
                await opponent.getAddress()
            );

            await rps.connect(account).commit(1, encryptedPick);
            await rps.connect(opponent).commit(1, encryptedPick)

            expect(() => rps.connect(account).reveal(
                1,
                pick1, seed1
            )).to.not.throw();
        });
    });
});
