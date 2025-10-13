import Test

access(all) let account = Test.createAccount()

access(all) fun testContract() {
    let err = Test.deployContract(
        name: "FlowTransactionScheduler",
        path: "../contracts/FlowTransactionScheduler.cdc",
        arguments: [],
    )

    Test.expect(err, Test.beNil())
}