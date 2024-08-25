module {
    public let network = "local";

    public func getTokenCanisterId() : Text {
        if (network == "ic") return "";
        if (network == "staging") return "";
        if (network == "beta") return "";
        // local
        return "b77ix-eeaaa-aaaaa-qaada-cai";
    };
    
    public func getDaoCanisterId() : Text {
        if (network == "ic") return "";
        if (network == "staging") return "";
        if (network == "beta") return "";
        // local
        return "bw4dl-smaaa-aaaaa-qaacq-cai";
    };
};
