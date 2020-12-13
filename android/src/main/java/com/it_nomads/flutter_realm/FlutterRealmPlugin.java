package com.it_nomads.flutter_realm;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.realm.Realm;

public class FlutterRealmPlugin implements MethodCallHandler {

    private FlutterRealmPlugin(MethodChannel channel) {
        this.channel = channel;
    }

    public static void registerWith(Registrar registrar) {
        Realm.init(registrar.context());

        final MethodChannel channel = new MethodChannel(registrar.messenger(), "plugins.it_nomads.com/flutter_realm");

        FlutterRealmPlugin plugin = new FlutterRealmPlugin(channel);
        channel.setMethodCallHandler(plugin);
    }

    private HashMap<String, FlutterRealm> realms = new HashMap<>();
    private final MethodChannel channel;

    @Override
    public void onMethodCall(MethodCall call, Result result) {

        try {
            Map arguments = (Map) call.arguments;

            switch (call.method) {
                case "initialize": {
                    onInitialize(result, arguments);
                    break;
                }
                case "reset":
                    onReset(result);
                    break;
                default: {
                    String realmId = (String) arguments.get("realmId");
                    FlutterRealm flutterRealm = realms.get(realmId);
                    if (flutterRealm == null) {
                        String message = "Method " + call.method + ":" + arguments.toString();
                        result.error("Realm not found", message, null);
                        return;
                    }

                    flutterRealm.onMethodCall(call, result);
                    break;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            result.error(e.getMessage(), e.getMessage(), e.getStackTrace().toString());
        }
    }

    private void onInitialize(Result result, Map arguments) {
        String realmId = (String) arguments.get("realmId");
        FlutterRealm flutterRealm = new FlutterRealm(channel, realmId, arguments);
        realms.put(realmId, flutterRealm);
        result.success(null);
    }

    private void onReset(Result result) {
        for (FlutterRealm realm : realms.values()) {
            realm.reset();
        }
        realms.clear();
        result.success(null);
    }




}
