import Result "mo:base/Result";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Types "types";
import Env "env";

actor class Dao() {

    type Result<A, B> = Result.Result<A, B>;
    type Member = Types.Member;
    type ProposalContent = Types.ProposalContent;
    type ProposalId = Types.ProposalId;
    type Proposal = Types.Proposal;
    type Vote = Types.Vote;
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;
    type TokenInterface = Types.TokenInterface;

    // The principal of the Webpage canister associated with this DAO canister (needs to be updated with the ID of your Webpage canister)
    stable let canisterIdWebpage : Principal = Principal.fromText("aaaaa-aa");
    stable var manifesto = "Test DAO to entrance into motoko";
    stable let name = "AS DAO";
    stable var goals : [Text] = [];

    let members = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);
    // set the initial mentor
    members.put(
        Principal.fromText("nkqop-siaaa-aaaaj-qa3qq-cai"),
        {
            name = "motoko_bootcamp";
            role = #Mentor;
        },
    );
    let proposals = HashMap.HashMap<ProposalId, Proposal>(0, Nat.equal, func(x : Nat) : Hash.Hash { Nat32.fromNat(x) });
    var nextProposalId : Nat = 0;
    let tokenCanisterEnv : Text = Env.getTokenCanisterId();
    let tokenActor : TokenInterface = actor (tokenCanisterEnv);

    // Returns the name of the DAO
    public query func getName() : async Text {
        return name;
    };

    // Returns the manifesto of the DAO
    public query func getManifesto() : async Text {
        return manifesto;
    };

    // Returns the goals of the DAO
    public query func getGoals() : async [Text] {
        return goals;
    };

    // Register a new member in the DAO with the given name and principal of the caller
    // Airdrop 10 MBT tokens to the new member
    // New members are always Student
    // Returns an error if the member already exists
    public shared ({ caller }) func registerMember(member : Member) : async Result<(), Text> {
        switch (members.get(caller)) {
            case (?member) {
                return #err("the member already exist");
            };
            case (null) {};
        };
        members.put(
            caller,
            {
                name = member.name;
                role = #Student;
            },
        );
        // airdrop 10 MBT to caller
        return await tokenActor.mint(caller, 10);
    };

    // Get the member with the given principal
    // Returns an error if the member does not exist
    public query func getMember(p : Principal) : async Result<Member, Text> {
        return switch (members.get(p)) {
            case (null) {
                #err("the member does not exist");
            };
            case (?member) {
                #ok(member);
            };
        };
    };

    // Graduate the student with the given principal
    // Returns an error if the student does not exist or is not a student
    // Returns an error if the caller is not a mentor
    public shared ({ caller }) func graduate(student : Principal) : async Result<(), Text> {
        switch (members.get(student)) {
            case (null) {
                return #err("the member does not exist");
            };
            case (?member) {
                if (member.role != #Student) {
                    return #err("the member is not student");
                };
                let callerRole = switch (members.get(caller)) {
                    case (null) { #Student };
                    case (?member) { member.role };
                };
                if (callerRole != #Mentor) {
                    return #err("caller is not mentor");
                };

                members.put(
                    student,
                    {
                        name = member.name;
                        role = #Graduate;
                    },
                );

                return #ok();
            };
        };
    };

    // Create a new proposal and returns its id
    // Returns an error if the caller is not a mentor or doesn't own at least 1 MBT token
    public shared ({ caller }) func createProposal(content : ProposalContent) : async Result<ProposalId, Text> {
        let callerRole = switch (members.get(caller)) {
            case (null) { #Student };
            case (?member) { member.role };
        };
        if (callerRole != #Mentor) {
            return #err("caller is not mentor");
        };
        // check caller's balance is greater than or equal with 1 MBT
        let balance = await tokenActor.balanceOf(caller);
        if (balance < 1) {
            return #err("member have insufficient balance");
        };
        // burn 1 MBT
        switch (await tokenActor.burn(caller, 1)) {
            case (#err(text)) {
                return #err(text);
            };
            case (_) {};
        };
        switch (content) {
            case (#AddMentor(principal)) {
                let memberRole = switch (members.get(principal)) {
                    case (null) {
                        #Student;
                    };
                    case (?member) {
                        member.role;
                    };
                };
                if (memberRole != #Graduate) {
                    return #err("the member is not graduate");
                };
            };
            case (_) {};
        };
        proposals.put(
            nextProposalId,
            {
                id = nextProposalId;
                content;
                creator = caller;
                created = Time.now();
                executed = null;
                votes = [];
                voteScore = 0;
                status = #Open;
            },
        );

        nextProposalId += 1;

        return #err("Not implemented");
    };

    // Get the proposal with the given id
    // Returns an error if the proposal does not exist
    public query func getProposal(id : ProposalId) : async Result<Proposal, Text> {
        switch (proposals.get(id)) {
            case (null) {
                return #err("the proposal does not exist");
            };
            case (?proposal) {
                return #ok(proposal);
            };
        };
    };

    // Returns all the proposals
    public query func getAllProposal() : async [Proposal] {
        Iter.toArray(proposals.vals());
    };

    // Vote for the given proposal
    // Returns an error if the proposal does not exist or the member is not allowed to vote
    public shared ({ caller }) func voteProposal(proposalId : ProposalId, yesOrNo : Bool) : async Result<(), Text> {
        switch (proposals.get(proposalId)) {
            case (null) {
                return #err("the proposal does not exist");
            };
            case (?proposal) {
                let callerRole = switch (members.get(caller)) {
                    case (null) { #Student };
                    case (?member) { member.role };
                };
                if (callerRole == #Student) {
                    return #err("the member can not vote");
                };

                if (_hasVoted(caller, proposal)) {
                    return #err("member have already voted");
                };

                let multiplier = switch ((callerRole, yesOrNo)) {
                    case ((#Mentor, true)) { 5 };
                    case ((#Mentor, false)) { -5 };
                    case ((#Graduate, true)) { 1 };
                    case ((#Graduate, false)) { -1 };
                    case (_) { 0 };
                };

                // get balance of caller;
                let callerBalance : Nat = 0;
                let votes = Buffer.fromArray<Vote>(proposal.votes);
                votes.add({
                    member = caller;
                    votingPower = callerBalance;
                    yesOrNo;
                });

                let newVoteScore = proposal.voteScore + multiplier * callerBalance;
                let newStatus = if (newVoteScore >= 100) {
                    #Accepted;
                } else if (newVoteScore <= -100) {
                    #Rejected;
                } else {
                    #Open;
                };
                let newExecuted : ?Time.Time = if (newStatus == #Accepted) {
                    ?Time.now();
                } else {
                    proposal.executed;
                };
                proposals.put(
                    proposalId,
                    {
                        id = proposalId;
                        content = proposal.content;
                        creator = caller;
                        created = proposal.created;
                        executed = newExecuted;
                        votes = Buffer.toArray<Vote>(votes);
                        voteScore = newVoteScore;
                        status = newStatus;
                    },
                );
                if (newStatus == #Accepted) {
                    return _executeProposal(proposal);
                };
            };
        };
        return #err("Not implemented");
    };

    func _hasVoted(member : Principal, proposal : Proposal) : Bool {
        return Array.find<Vote>(proposal.votes, func(vote : Vote) : Bool { vote.member == member }) != null;
    };

    func _executeProposal(proposal : Proposal) : Result<(), Text> {
        switch (proposal.content) {
            case (#ChangeManifesto(text)) {
                manifesto := text;
                #ok();
            };
            case (#AddGoal(text)) {
                _addGoal(text);
                #ok();
            };
            case (#AddMentor(principal)) {
                return _addMentor(principal);
            };
        };
    };

    func _addGoal(text : Text) : () {
        let goalBuffer : Buffer.Buffer<Text> = Buffer.fromArray<Text>(goals);
        goalBuffer.add(text);
        goals := Buffer.toArray<Text>(goalBuffer);
    };

    func _addMentor(principal : Principal) : Result<(), Text> {
        switch (members.get(principal)) {
            case (null) {
                return #err("the member does not exist");
            };
            case (?member) {
                members.put(
                    principal,
                    {
                        name = member.name;
                        role = #Mentor;
                    },
                );
                return #ok();
            };
        };
    };

    // Returns the Principal ID of the Webpage canister associated with this DAO canister
    public query func getIdWebpage() : async Principal {
        return canisterIdWebpage;
    };

};
