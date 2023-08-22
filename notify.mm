#include <napi.h>

#include <map>

// Apple APIs
#import <Foundation/Foundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/pwr_mgt/IOPM.h>
#include <IOKit/pwr_mgt/IOPMKeys.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/pwr_mgt/IOPMLibDefs.h>
#include <notify.h>

Napi::ThreadSafeFunction ts_fn;
std::map<int, std::string> observers;

/***** HELPER FUNCTIONS *****/

/***** EXPORTED FUNCTIONS *****/

Napi::Value SendSystemNotification(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string type = info[0].As<Napi::String>().Utf8Value();
  uint32_t result = notify_post(type.c_str());

  return Napi::Number::From(env, result);
}

Napi::Boolean SetupListener(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string key = info[0].As<Napi::String>().Utf8Value();

  for (auto &it : observers) {
    if (it.second == key) {
      Napi::Error::New(env, "An observer is already observing " + key)
          .ThrowAsJavaScriptException();
      return Napi::Boolean::New(env, false);
    }
  }

  ts_fn = Napi::ThreadSafeFunction::New(env, info[1].As<Napi::Function>(),
                                        "emitCallback", 0, 1);

  auto on_change_block = ^(int x) {
    auto callback = [](Napi::Env env, Napi::Function js_cb, const char *val) {
      js_cb.Call({Napi::String::New(env, val)});
    };
    ts_fn.BlockingCall(key.c_str(), callback);
  };

  int registration_token;
  uint32_t status = notify_register_dispatch(
      key.c_str(), &registration_token, dispatch_get_main_queue(), ^(int x) {
        on_change_block(x);
      });

  if (status != 0) {
    Napi::Error::New(env, "Failed to register for " + key)
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  observers.emplace(registration_token, key);
  return Napi::Boolean::New(env, true);
}

Napi::Boolean CheckNotification(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string key = info[0].As<Napi::String>().Utf8Value();

  int registration_token;
  for (auto &it : observers) {
    if (it.second == key) {
      registration_token = it.first;
    }
  }

  if (!registration_token) {
    Napi::Error::New(env, "No observer exists for " +
                              observers.at(registration_token))
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  int called;
  notify_check(registration_token, &called);

  return Napi::Boolean::New(env, called);
}

Napi::Boolean RemoveListener(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string key = info[0].As<Napi::String>().Utf8Value();

  int registration_token;
  for (auto &it : observers) {
    if (it.second == key) {
      registration_token = it.first;
    }
  }

  if (!registration_token) {
    Napi::Error::New(env, "No observer exists for " + key)
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  notify_cancel(registration_token);
  observers.erase(registration_token);

  return Napi::Boolean::New(env, true);
}

// Initializes all functions exposed to JS
Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set(Napi::String::New(env, "setupListener"),
              Napi::Function::New(env, SetupListener));
  exports.Set(Napi::String::New(env, "removeListener"),
              Napi::Function::New(env, RemoveListener));
  exports.Set(Napi::String::New(env, "checkNotification"),
              Napi::Function::New(env, CheckNotification));
  exports.Set(Napi::String::New(env, "sendSystemNotification"),
              Napi::Function::New(env, SendSystemNotification));

  return exports;
}

NODE_API_MODULE(notify, Init)
