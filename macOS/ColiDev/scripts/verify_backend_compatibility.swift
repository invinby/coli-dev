import Foundation

let compatibleStatus = Data(
    #"{"product_id":"colidev","api_version":1,"api_compatibility":{"minimum_client_version":1,"maximum_client_version":1},"build_id":"ci-abc123"}"#.utf8
)
precondition(
    BackendCompatibility.evaluate(compatibleStatus) == .compatible(apiVersion: 1, buildID: "ci-abc123"),
    "a matching ColiDev API status must be accepted"
)

let oldBackendStatus = Data(
    #"{"service":"coli-dev Orchestrator v4.0","version":"4.0.0"}"#.utf8
)
if case .compatible = BackendCompatibility.evaluate(oldBackendStatus) {
    fatalError("an old unversioned backend must be rejected")
}

let otherProductStatus = Data(
    #"{"product_id":"another-app","api_version":1,"api_compatibility":{"minimum_client_version":1,"maximum_client_version":1},"build_id":"ci-abc123"}"#.utf8
)
if case .compatible = BackendCompatibility.evaluate(otherProductStatus) {
    fatalError("a different product must be rejected")
}

let unsupportedVersionStatus = Data(
    #"{"product_id":"colidev","api_version":2,"api_compatibility":{"minimum_client_version":2,"maximum_client_version":3},"build_id":"ci-abc123"}"#.utf8
)
if case .compatible = BackendCompatibility.evaluate(unsupportedVersionStatus) {
    fatalError("a backend that excludes this client version must be rejected")
}

let missingBuildStatus = Data(
    #"{"product_id":"colidev","api_version":1,"api_compatibility":{"minimum_client_version":1,"maximum_client_version":1},"build_id":"  "}"#.utf8
)
if case .compatible = BackendCompatibility.evaluate(missingBuildStatus) {
    fatalError("a backend without a build identifier must be rejected")
}

precondition(BackendEndpointRegistry.defaultPort == 8000)
print("Backend compatibility contract verified.")
