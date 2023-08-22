#include <napi.h>

// Apple APIs
#import <Foundation/Foundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/pwr_mgt/IOPM.h>
#include <IOKit/pwr_mgt/IOPMKeys.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/pwr_mgt/IOPMLibDefs.h>
#include <notify.h>

/***** HELPER FUNCTIONS *****/

/***** EXPORTED FUNCTIONS *****/

Napi::Value SendSystemNotification(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  const std::string type = info[0].As<Napi::String>().Utf8Value();
  uint32_t result = notify_post(type.c_str());

  return Napi::Number::From(env, result);
}

// Initializes all functions exposed to JS
Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set(Napi::String::New(env, "sendSystemNotification"),
              Napi::Function::New(env, SendSystemNotification));

  return exports;
}

NODE_API_MODULE(notify, Init)
