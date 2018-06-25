import { NativeModules } from 'react-native';

const tim = NativeModules.TIM;

export default class TIM {
  // {sdkAppId :””, accountType : “”}
  static initSDK(params) {
    return tim.initSdk(params);
  }
  // {sdkAppId :””, accountType : “”}
  static setUserConfig(params) {
    return tim.setUserConfig(params);
  }
  // {userSig :””, appidAt3rd : “”,identifier:””}
  static login(params) {
    return tim.login(params);
  }
  // {msg :””, type :1,receiver:””}
  static sendMsg(params) {
    return tim.sendMsg(params);
  }
}
