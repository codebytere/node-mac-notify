#include <napi.h>

#include <dispatch/dispatch.h>
#include <notify.h>

#include <map>

// Apple APIs
#import <Foundation/Foundation.h>

Napi::ThreadSafeFunction ts_fn;
std::map<int, std::string> observers;

/***** EXPORTED FUNCTIONS *****/

Napi::Value SendSystemNotification(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string event_key = info[0].As<Napi::String>().Utf8Value();
  uint32_t result = notify_post(event_key.c_str());

  return Napi::Number::From(env, result);
}

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
    Napi::Error::New(env, "Failed to register for " + event_key)
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  observers.emplace(registration_token, event_key);

  return Napi::Boolean::New(env, true);
}

Napi::Boolean SuspendListener(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string event_key = info[0].As<Napi::String>().Utf8Value();

  int registration_token;
  for (auto &it : observers) {
    if (it.second == event_key)
      registration_token = it.first;
  }

  if (!registration_token) {
    Napi::Error::New(env, "No observer exists for " + event_key)
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  uint32_t status = notify_suspend(registration_token);

  if (status != NOTIFY_STATUS_OK) {
    Napi::Error::New(env, "Failed to suspend notifications for " + event_key)
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  return Napi::Boolean::New(env, true);
}

Napi::Boolean RemoveListener(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string event_key = info[0].As<Napi::String>().Utf8Value();

  int registration_token;
  for (auto &it : observers) {
    if (it.second == event_key)
      registration_token = it.first;
  }

  if (!registration_token) {
    Napi::Error::New(env, "No observer exists for " + event_key)
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  uint32_t status = notify_cancel(registration_token);

  if (status != NOTIFY_STATUS_OK) {
    Napi::Error::New(env, "Failed to deregister for " + event_key)
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  observers.erase(registration_token);

  return Napi::Boolean::New(env, true);
}

// Initializes all functions exposed to JS
Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set(Napi::String::New(env, "addListener"),
              Napi::Function::New(env, AddListener));
  exports.Set(Napi::String::New(env, "removeListener"),
              Napi::Function::New(env, RemoveListener));
  exports.Set(Napi::String::New(env, "suspendListener"),
              Napi::Function::New(env, SuspendListener));
  exports.Set(Napi::String::New(env, "sendSystemNotification"),
              Napi::Function::New(env, SendSystemNotification));

  return exports;
}

NODE_API_MODULE(notify, Init)
