import android.os.IBinder;
import android.view.InputDevice;
import java.lang.reflect.Method;

/** One-shot shell helper for Android 12 keyboard layout selection. */
public final class LayoutControl {
    public static void main(String[] args) throws Exception {
        Class<?> sm = Class.forName("android.os.ServiceManager");
        IBinder binder = (IBinder)sm.getMethod("getService", String.class).invoke(null, "input");
        Class<?> stub = Class.forName("android.hardware.input.IInputManager$Stub");
        Object service = stub.getMethod("asInterface", IBinder.class).invoke(null, binder);
        Class<?> api = Class.forName("android.hardware.input.IInputManager");
        Class<?> identifierClass = Class.forName("android.hardware.input.InputDeviceIdentifier");
        InputDevice target = null;
        for (int id : InputDevice.getDeviceIds()) {
            InputDevice device = InputDevice.getDevice(id);
            if (device != null && device.getVendorId() == 0x248a && device.getProductId() == 0x8266) {
                target = device;
                break;
            }
        }
        if (target == null) throw new IllegalStateException("DARLING is not connected");
        Object identifier = identifierClass.getConstructor(String.class, int.class, int.class)
            .newInstance(target.getDescriptor(), target.getVendorId(), target.getProductId());
        Method current = api.getMethod("getCurrentKeyboardLayoutForInputDevice", identifierClass);
        System.out.println("DEVICE " + target.getName() + " descriptor=" + target.getDescriptor());
        System.out.println("BEFORE " + current.invoke(service, identifier));
        if (args.length == 2 && args[0].equals("apply")) {
            api.getMethod("addKeyboardLayoutForInputDevice", identifierClass, String.class)
                .invoke(service, identifier, args[1]);
            api.getMethod("setCurrentKeyboardLayoutForInputDevice", identifierClass, String.class)
                .invoke(service, identifier, args[1]);
        } else if (args.length == 2 && args[0].equals("remove")) {
            api.getMethod("removeKeyboardLayoutForInputDevice", identifierClass, String.class)
                .invoke(service, identifier, args[1]);
        } else if (args.length != 0) {
            throw new IllegalArgumentException("Usage: LayoutControl [apply|remove layout-id]");
        }
        System.out.println("AFTER " + current.invoke(service, identifier));
        Object[] layouts = (Object[])api.getMethod("getKeyboardLayouts").invoke(service);
        for (Object layout : layouts) {
            String value = layout.toString();
            if (value.contains("DARLING")) {
                System.out.println("AVAILABLE " + layout.getClass().getMethod("getDescriptor").invoke(layout));
            }
        }
        System.exit(0);
    }
}
