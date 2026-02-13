#include "TdBridge.h"
#include "td/telegram/Client.h"
#include <iostream>
#include <chrono>

std::shared_ptr<TdBridge> TdBridge::getInstance() {
    static std::shared_ptr<TdBridge> instance = std::make_shared<TdBridge>();
    return instance;
}

TdBridge::TdBridge() {
    // Initialize TDLib client
    clientManager = std::make_shared<td::ClientManager>();
    clientId = clientManager->create_client_id();

    // Start receiver thread for handling updates
    shouldRun = true;
    receiverThread = std::make_unique<std::thread>(&TdBridge::receiverLoop, this);
}

TdBridge::~TdBridge() {
    shutdown();
}

void TdBridge::shutdown() {
    shouldRun = false;
    if (receiverThread && receiverThread->joinable()) {
        receiverThread->join();
    }
}

int TdBridge::send(const std::string& query) {
    if (!clientManager) {
        return -1;
    }
    clientManager->send(clientId, query);
    return clientId;
}

std::string TdBridge::receive(double timeout_ms) {
    if (!clientManager) {
        return "";
    }

    auto response = clientManager->receive(timeout_ms);
    if (response.object) {
        // Convert response object to JSON string
        // For now, return a placeholder - actual implementation depends on TDLib version
        return response.object;
    }
    return "";
}

std::string TdBridge::execute(const std::string& query) {
    if (!clientManager) {
        return "";
    }

    // Execute synchronously (only for initialization)
    auto response = clientManager->execute(query);
    if (response.object) {
        return response.object;
    }
    return "";
}

void TdBridge::setUpdateCallback(std::function<void(const std::string&)> callback) {
    std::lock_guard<std::mutex> lock(callbackMutex);
    updateCallback = callback;
}

bool TdBridge::isAuthorized() const {
    return authorized;
}

std::string TdBridge::getAuthorizationState() const {
    return currentAuthState;
}

void TdBridge::receiverLoop() {
    const double timeout_ms = 1000.0; // 1 second timeout

    while (shouldRun) {
        try {
            auto response = clientManager->receive(timeout_ms);
            if (response.object) {
                std::string update = response.object;

                // Check if this is an authorization state update
                if (update.find("authorizationStateReady") != std::string::npos) {
                    authorized = true;
                    currentAuthState = "ready";
                } else if (update.find("authorizationState") != std::string::npos) {
                    currentAuthState = update;
                }

                // Call the registered callback
                handleUpdate(update);
            }
        } catch (const std::exception& e) {
            std::cerr << "Error in receiver loop: " << e.what() << std::endl;
        }
    }
}

void TdBridge::handleUpdate(const std::string& update) {
    std::lock_guard<std::mutex> lock(callbackMutex);
    if (updateCallback) {
        updateCallback(update);
    }
}
