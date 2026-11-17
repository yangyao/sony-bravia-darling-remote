#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hid/IOHIDManager.h>
#include <stdio.h>
#include <time.h>

static void input(void *context, IOReturn result, void *sender, IOHIDValueRef value) {
    IOHIDElementRef element = IOHIDValueGetElement(value);
    printf("EVENT time=%ld page=0x%04x usage=0x%04x value=%ld report=%u\n",
           (long)time(NULL), IOHIDElementGetUsagePage(element), IOHIDElementGetUsage(element),
           (long)IOHIDValueGetIntegerValue(value), IOHIDElementGetReportID(element));
    fflush(stdout);
}

static void matched(void *context, IOReturn result, void *sender, IOHIDDeviceRef device) {
    printf("DEVICE_MATCHED result=0x%x\n", result);
    fflush(stdout);
}

int main(void) {
    setbuf(stdout, NULL);
    IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    int vendor = 0x248a, product = 0x8266;
    CFNumberRef vid = CFNumberCreate(NULL, kCFNumberIntType, &vendor);
    CFNumberRef pid = CFNumberCreate(NULL, kCFNumberIntType, &product);
    const void *keys[] = {CFSTR(kIOHIDVendorIDKey), CFSTR(kIOHIDProductIDKey), CFSTR(kIOHIDProductKey)};
    const void *values[] = {vid, pid, CFSTR("tKeybd")};
    CFDictionaryRef match = CFDictionaryCreate(NULL, keys, values, 3,
                                              &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    IOHIDManagerSetDeviceMatching(manager, match);
    IOHIDManagerRegisterDeviceMatchingCallback(manager, matched, NULL);
    IOHIDManagerRegisterInputValueCallback(manager, input, NULL);
    IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOReturn status = IOHIDManagerOpen(manager, kIOHIDOptionsTypeNone);
    printf("OPEN status=0x%x target=tKeybd VID=248a PID=8266\n", status);
    if (status != kIOReturnSuccess) return 1;
    printf("READY: listening only to tKeybd; Ctrl-C to stop\n");
    CFRunLoopRun();
    return 0;
}
