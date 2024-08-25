import Result "mo:base/Result";
import Principal "mo:base/Principal";
import { test; suite; skip; expect } "mo:test/async";
import Dao "../src/dao/main";
import Token "../src/token/main";
import Types "../src/dao/types";

// setup canisters
let tokenActor = await Token.Token();
let daoActor = await Dao.Dao(Principal.fromActor(tokenActor));

type Member = Types.Member;
type Result<A, B> = Result.Result<A, B>;

actor class WhoAmI() {
    public query ({ caller }) func whoami() : async Principal {
        return caller;
    };
};
let whoAmIActor = await WhoAmI();

await suite(
    "Dao",
    func() : async () {
        await suite(
            "registerMember",
            func() : async () {
                await test(
                    "should register with success",
                    func() : async () {
                        let resDao = await daoActor.registerMember({
                            name = "Alice";
                            role = #Student;
                        });

                        func show(a : Result<(), Text>) : Text = debug_show (a);
                        func equal(a : Result<(), Text>, b : Result<(), Text>) : Bool = a == b;
                        expect.result<(), Text>(resDao, show, equal).isOk();
                    },
                );
                await test(
                    "should airdrop tokens",
                    func() : async () {
                        let myPrincipal : Principal = await whoAmIActor.whoami();
                        let resAmount = await tokenActor.balanceOf(myPrincipal);

                        expect.nat(resAmount).equal(10);
                    },
                );
            },
        );
    },
);
