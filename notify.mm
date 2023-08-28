#include <napi.h>

#include <dispatch/dispatch.h>
#include <notify.h>

#include <map>

// Apple APIs
#import <Foundation/Foundation.h>

Napi::ThreadSafeFunction ts_fn;
std::map<int, std::string> observers;

/***** HELPER FUNCTIONS *****/

// Returns a human-readable error message from a Darwin Notification status
// code.
std::string ErrorMessageFromStatus(uint32_t status) {
  switch (status) {
  case NOTIFY_STATUS_INVALID_FILE:
    return "Invalid File";
  case NOTIFY_STATUS_INVALID_NAME:
    return "Invalid Name";
  case NOTIFY_STATUS_INVALID_PORT:
    return "Invalid Port";
  case NOTIFY_STATUS_INVALID_REQUEST:
    return "Invalid Request";
  case NOTIFY_STATUS_INVALID_SIGNAL:
    return "Invalid Signal";
  case NOTIFY_STATUS_INVALID_TOKEN:
    return "Invalid Token";
  case NOTIFY_STATUS_NOT_AUTHORIZED:
    return "Not Authorized";
  case NOTIFY_STATUS_FAILED:
  default:
    return "Unknown Failure";
  }
}

// Returns the registration token for a given event key, or -1 if no observer
// exists.
int GetTokenFromEventKey(const std::string &event_key) {
  bool found = false;

  int registration_token;
  for (auto &it : observers) {
    if (it.second == event_key) {
      found = true;
      registration_token = it.first;
    }
  }

  return found ? registration_token : -1;
}

/***** EXPORTED FUNCTIONS *****/

// Sends a Darwin Notification for the given name to all clients that have
// registered for notifications of this name.
Napi::Boolean PostNotification(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string event_key = info[0].As<Napi::String>().Utf8Value();
  uint32_t status = notify_post(event_key.c_str());

  if (status != NOTIFY_STATUS_OK) {
    Napi::Error::New(env, "Failed to post a notification for " + event_key +
                              ": " + ErrorMessageFromStatus(status))
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  return Napi::Boolean::New(env, true);
}

Napi::Boolean SetState(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string event_key = info[0].As<Napi::String>().Utf8Value();

  int registration_token = GetTokenFromEventKey(event_key);
  if (registration_token == -1) {
    Napi::Error::New(env, "No registration token exists for " + event_key)
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  bool lossless = true;
  uint64_t new_state = info[1].As<Napi::BigInt>().Uint64Value(&lossless);
  if (!lossless)
    fprintf(stderr, "setState: State value %llx was truncated\n", new_state);

  uint32_t status = notify_set_state(registration_token, new_state);

  if (status != NOTIFY_STATUS_OK) {
    Napi::Error::New(env, "Failed to set state for " + event_key + ": " +
                              ErrorMessageFromStatus(status))
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  return Napi::Boolean::New(env, true);
}

Napi::BigInt GetState(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string event_key = info[0].As<Napi::String>().Utf8Value();

  int registration_token = GetTokenFromEventKey(event_key);
  if (registration_token == -1) {
    Napi::Error::New(env, "No registration token exists for " + event_key)
        .ThrowAsJavaScriptException();
    return Napi::BigInt();
  }

  uint64_t state;
  uint32_t status = notify_get_state(registration_token, &state);

  if (status != NOTIFY_STATUS_OK) {
    Napi::Error::New(env, "Failed to fetch state for " + event_key + ": " +
                              ErrorMessageFromStatus(status))
        .ThrowAsJavaScriptException();
    return Napi::BigInt();
  }

  return Napi::BigInt::New(env, state);
}

// Adds a listener for a Darwin Notification.
Napi::Boolean AddListener(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  __block const std::string event_key = info[0].As<Napi::String>().Utf8Value();

  for (auto &it : observers) {
    if (it.second == event_key) {
      Napi::Error::New(env, "An observer is already observing " + event_key)
          .ThrowAsJavaScriptException();
      return Napi::Boolean::New(env, false);
    }
  }

  ts_fn = Napi::ThreadSafeFunction::New(env, info[1].As<Napi::Function>(),
                                        "emitCallback", 0, 1);

  auto on_change_block = ^() {
    auto callback = [](Napi::Env env, Napi::Function js_cb,
                       const char *event_name) {
      js_cb.Call({Napi::String::New(env, event_name)});
    };

    const char *event = event_key.c_str();
    ts_fn.BlockingCall(event, callback);
  };

  int registration_token;
  uint32_t status = notify_register_dispatch(
      event_key.c_str(), &registration_token,
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(int) {
        on_change_block();
      });

  if (status != NOTIFY_STATUS_OK) {
    Napi::Error::New(env, "Failed to register for " + event_key + ": " +
                              ErrorMessageFromStatus(status))
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  observers.emplace(registration_token, event_key);

  return Napi::Boolean::New(env, true);
}

// Suspends a listener for a Darwin Notification.
Napi::Boolean SuspendListener(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string event_key = info[0].As<Napi::String>().Utf8Value();

  int registration_token = GetTokenFromEventKey(event_key);
  if (registration_token == -1) {
    Napi::Error::New(env, "No observer exists for " + event_key)
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  uint32_t status = notify_suspend(registration_token);

  if (status != NOTIFY_STATUS_OK) {
    Napi::Error::New(env, "Failed to suspend notifications for " + event_key +
                              ": " + ErrorMessageFromStatus(status))
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  return Napi::Boolean::New(env, true);
}

// Resumes a suspended listener for a Darwin Notification.
Napi::Boolean ResumeListener(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string event_key = info[0].As<Napi::String>().Utf8Value();

  int registration_token = GetTokenFromEventKey(event_key);
  if (registration_token == -1) {
    Napi::Error::New(env, "No observer exists for " + event_key)
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  uint32_t status = notify_resume(registration_token);

  if (status != NOTIFY_STATUS_OK) {

    Napi::Error::New(env, "Failed to resume notifications for " + event_key +
                              ": " + ErrorMessageFromStatus(status))
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  return Napi::Boolean::New(env, true);
}

// Removes a listener for a Darwin Notification.
Napi::Boolean RemoveListener(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string event_key = info[0].As<Napi::String>().Utf8Value();

  int registration_token = GetTokenFromEventKey(event_key);
  if (registration_token == -1) {
    Napi::Error::New(env, "No observer exists for " + event_key)
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  uint32_t status = notify_cancel(registration_token);

  if (status != NOTIFY_STATUS_OK) {
    Napi::Error::New(env, "Failed to deregister for " + event_key + ": " +
                              ErrorMessageFromStatus(status))
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  observers.erase(registration_token);

  ts_fn.Release();

  return Napi::Boolean::New(env, true);
}

// Initializes all functions exposed to JS
Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set(Napi::String::New(env, "postNotification"),
              Napi::Function::New(env, PostNotification));
  exports.Set(Napi::String::New(env, "setState"),
              Napi::Function::New(env, SetState));
  exports.Set(Napi::String::New(env, "getState"),
              Napi::Function::New(env, GetState));
  exports.Set(Napi::String::New(env, "addListener"),
              Napi::Function::New(env, AddListener));
  exports.Set(Napi::String::New(env, "removeListener"),
              Napi::Function::New(env, RemoveListener));
  exports.Set(Napi::String::New(env, "suspendListener"),
              Napi::Function::New(env, SuspendListener));
  exports.Set(Napi::String::New(env, "resumeListener"),
              Napi::Function::New(env, ResumeListener));

  return exports;
}

NODE_API_MODULE(notify, Init)
