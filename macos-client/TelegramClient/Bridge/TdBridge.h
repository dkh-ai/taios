#ifndef TD_BRIDGE_H
#define TD_BRIDGE_H

#include <string>
#include <memory>
#include <functional>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <thread>

// Forward declarations
namespace td {
    class ClientManager;
}

/**
 * TdBridge - Wrapper around TDLib for C++/Swift interoperability
 *
 * This class provides a thread-safe, asynchronous interface to TDLib
 * suitable for integration with Swift/macOS applications.
 *
 * Usage:
 *   auto bridge = TdBridge::getInstance();
 *   bridge->execute("{\"@type\":\"setTdlibParameters\", ...}");
 *   auto response = bridge->receive(timeout_ms);
 */
class TdBridge {
public:
    // Singleton instance
    static std::shared_ptr<TdBridge> getInstance();

    /**
     * Send a query to TDLib
     * @param query JSON-formatted TDLib query
     * @return client_id associated with this query
     */
    int send(const std::string& query);

    /**
     * Receive a response from TDLib (blocking)
     * @param timeout_ms Timeout in milliseconds. 0 = non-blocking, -1 = infinite
     * @return JSON response from TDLib or empty string if timeout
     */
    std::string receive(double timeout_ms);

    /**
     * Synchronous execute (only for initialization queries)
     * @param query JSON-formatted query
     * @return JSON response
     */
    std::string execute(const std::string& query);

    /**
     * Set callback for incoming updates
     * @param callback Function to call when update is received
     */
    void setUpdateCallback(std::function<void(const std::string&)> callback);

    /**
     * Check if client is authorized
     * @return true if in authorized state
     */
    bool isAuthorized() const;

    /**
     * Get current authorization state
     * @return JSON string with current auth state
     */
    std::string getAuthorizationState() const;

    /**
     * Shutdown the client (cleanup resources)
     */
    void shutdown();

    // Destructor
    ~TdBridge();

    // Delete copy operations
    TdBridge(const TdBridge&) = delete;
    TdBridge& operator=(const TdBridge&) = delete;

private:
    TdBridge();

    std::shared_ptr<td::ClientManager> clientManager;
    int clientId = 0;
    bool authorized = false;
    std::string currentAuthState;

    std::function<void(const std::string&)> updateCallback;
    std::mutex callbackMutex;

    // Update receiver thread
    std::unique_ptr<std::thread> receiverThread;
    std::atomic<bool> shouldRun{true};

    void receiverLoop();
    void handleUpdate(const std::string& update);
};

#endif // TD_BRIDGE_H
