import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import {test; suite; skip} "mo:test/async";
import Fuzz "mo:fuzz";
import Dao "../../src/dao/main";
import Types "../../src/dao/types";

let dao = await Dao.Dao();
let fuzz = Fuzz.Fuzz();
type Member = Types.Member;
type Result<A, B> = Result.Result<A, B>;

actor class DaoWrapper(canister : Dao.Dao) = this {
    func getPrincipal() : Principal {
        return Principal.fromActor(this);
    };
    public func registerMember(member : Member) : async Result<Principal, Text> {
        return switch (await canister.registerMember(member)) {
            case (#ok()) {
                return #ok(getPrincipal());
            };
            case (#err(text)) {
                return #err(text);
            };
        };
    }
};

await suite("member management", func() : async () {
	await test("success of registering member", func() : async () {
        let forAlice = await DaoWrapper(dao);
        let forBob = await DaoWrapper(dao);
        let resAlice = await forAlice.registerMember({
            name = "Alice";
            role = #Student;
        });
        assert Result.isOk(resAlice);
        let alice : Principal = switch (resAlice) {
            case (#ok(principal)) {principal};
            case (#err(text)) {Principal.fromText("aaaa-aa")};
        };
        let resBob = await forBob.registerMember({
            name = "Alice";
            role = #Student;
        });
        assert Result.isOk(resBob);
        let bob : Principal = switch (resBob) {
            case (#ok(principal)) {principal};
            case (#err(text)) {Principal.fromText("aaaa-aa")};
        };

        let memberAlice = await dao.getMember(alice);
        let memberBob = await dao.getMember(bob);

        assert Result.isOk(memberAlice);
        assert Result.isOk(memberBob);

        switch (memberAlice) {
            case (#ok(member)) {
                assert (member.name == "Alice");
                assert (member.role == #Student);
            };
            case (#err(text)) {};
        };
        switch (memberBob) {
            case (#ok(member)) {
                assert (member.name == "Bob");
                assert (member.role == #Student);
            };
            case (#err(text)) {};
        };

        // check balance of alice & bob
    });
});