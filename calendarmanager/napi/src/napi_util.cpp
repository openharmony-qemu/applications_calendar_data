/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "napi_util.h"
#include <endian.h>
#include <securec.h>
#include "calendar_log.h"
#include "napi_queue.h"
#include "native_util.h"
#include "event_filter_napi.h"

namespace OHOS::CalendarApi::NapiUtil {
constexpr int32_t STR_MAX_LENGTH = 4096;
constexpr size_t STR_TAIL_LENGTH = 1;

napi_status GetValue(napi_env env, napi_value in, napi_value& out)
{
    out = in;
    return napi_ok;
}

napi_status SetValue(napi_env env, napi_value in, napi_value& out)
{
    out = in;
    return napi_ok;
}

/* napi_value <-> bool */
napi_status GetValue(napi_env env, napi_value in, bool& out)
{
    return napi_get_value_bool(env, in, &out);
}

napi_status SetValue(napi_env env, const bool& in, napi_value& out)
{
    return napi_get_boolean(env, in, &out);
}

/* napi_value <-> int32_t */
napi_status GetValue(napi_env env, napi_value in, int32_t& out)
{
    return napi_get_value_int32(env, in, &out);
}

napi_status SetValue(napi_env env, const int32_t& in, napi_value& out)
{
    return napi_create_int32(env, in, &out);
}

/* napi_value <-> uint32_t */
napi_status GetValue(napi_env env, napi_value in, uint32_t& out)
{
    return napi_get_value_uint32(env, in, &out);
}

napi_status SetValue(napi_env env, const uint32_t& in, napi_value& out)
{
    return napi_create_uint32(env, in, &out);
}

/* napi_value <-> int64_t */
napi_status GetValue(napi_env env, napi_value in, int64_t& out)
{
    return napi_get_value_int64(env, in, &out);
}

napi_status SetValue(napi_env env, const int64_t& in, napi_value& out)
{
    return napi_create_int64(env, in, &out);
}

napi_status GetValue(napi_env env, napi_value in, uint64_t& out)
{
    bool lossless = true;
    return napi_get_value_bigint_uint64(env, in, &out, &lossless);
}

napi_status SetValue(napi_env env, const uint64_t& in, napi_value& out)
{
    return napi_create_bigint_uint64(env, in, &out);
}

/* napi_value <-> double */
napi_status GetValue(napi_env env, napi_value in, double& out)
{
    return napi_get_value_double(env, in, &out);
}

napi_status SetValue(napi_env env, const double& in, napi_value& out)
{
    return napi_create_double(env, in, &out);
}

/* napi_value <-> std::string */
napi_status GetValue(napi_env env, napi_value in, std::string& out)
{
    napi_valuetype type = napi_undefined;
    napi_status status = napi_typeof(env, in, &type);
    CHECK_RETURN((status == napi_ok) && (type == napi_string), "invalid type", napi_invalid_arg);

    size_t maxLen = STR_MAX_LENGTH;
    status = napi_get_value_string_utf8(env, in, NULL, 0, &maxLen);
    if (maxLen <= 0) {
        return status;
    }
    LOG_DEBUG("napi_value -> std::string get length %{public}d", (int)maxLen);
    char* buf = new (std::nothrow) char[maxLen + STR_TAIL_LENGTH];
    if (buf != nullptr) {
        size_t len = 0;
        status = napi_get_value_string_utf8(env, in, buf, maxLen + STR_TAIL_LENGTH, &len);
        if (status == napi_ok) {
            buf[len] = 0;
            out = std::string(buf);
        }
        delete[] buf;
    } else {
        status = napi_generic_failure;
    }
    return status;
}

napi_status SetValue(napi_env env, const std::string& in, napi_value& out)
{
    return napi_create_string_utf8(env, in.c_str(), in.size(), &out);
}

/* napi_value <-> std::vector<std::string> */
napi_status GetValue(napi_env env, napi_value in, std::vector<std::string>& out)
{
    LOG_DEBUG("napi_value -> std::vector<std::string>");
    return GetValueArray(env, in, out);;
}

napi_status SetValue(napi_env env, const std::vector<std::string>& in, napi_value& out)
{
    LOG_DEBUG("napi_value <- std::vector<std::string>");
    napi_status status = napi_create_array_with_length(env, in.size(), &out);
    CHECK_RETURN(status == napi_ok, "create array failed!", status);
    int index = 0;
    for (auto& item : in) {
        napi_value element = nullptr;
        SetValue(env, item, element);
        status = napi_set_element(env, out, index++, element);
        CHECK_RETURN((status == napi_ok), "napi_set_element failed!", status);
    }
    return status;
}

/* napi_value <-> std::vector<uint8_t> */
napi_status GetValue(napi_env env, napi_value in, std::vector<uint8_t>& out)
{
    out.clear();
    LOG_DEBUG("napi_value -> std::vector<uint8_t> ");
    napi_typedarray_type type = napi_biguint64_array;
    size_t length = 0;
    napi_value buffer = nullptr;
    size_t offset = 0;
    void* data = nullptr;
    napi_status status = napi_get_typedarray_info(env, in, &type, &length, &data, &buffer, &offset);
    LOG_DEBUG("array type=%{public}d length=%{public}d offset=%{public}d", (int)type, (int)length, (int)offset);
    CHECK_RETURN(status == napi_ok, "napi_get_typedarray_info failed!", napi_invalid_arg);
    CHECK_RETURN(type == napi_uint8_array, "is not Uint8Array!", napi_invalid_arg);
    CHECK_RETURN((length > 0) && (data != nullptr), "invalid data!", napi_invalid_arg);
    out.assign((uint8_t*)data, ((uint8_t*)data) + length);
    return status;
}

napi_status SetValue(napi_env env, const std::vector<uint8_t>& in, napi_value& out)
{
    LOG_DEBUG("napi_value <- std::vector<uint8_t> ");
    CHECK_RETURN(in.size() > 0, "invalid std::vector<uint8_t>", napi_invalid_arg);
    void* data = nullptr;
    napi_value buffer = nullptr;
    napi_status status = napi_create_arraybuffer(env, in.size(), &data, &buffer);
    CHECK_RETURN((status == napi_ok), "create array buffer failed!", status);

    if (memcpy_s(data, in.size(), in.data(), in.size()) != EOK) {
        LOG_ERROR("memcpy_s not EOK");
        return napi_invalid_arg;
    }
    status = napi_create_typedarray(env, napi_uint8_array, in.size(), buffer, 0, &out);
    CHECK_RETURN((status == napi_ok), "napi_value <- std::vector<uint8_t> invalid value", status);
    return status;
}

/* napi_value <-> std::vector<int32_t> */
napi_status GetValue(napi_env env, napi_value in, std::vector<int32_t>& out)
{
    LOG_DEBUG("napi_value -> std::vector<int32_t> ");
    return GetValueArray(env, in, out);
}

napi_status SetValue(napi_env env, const std::vector<int32_t>& in, napi_value& out)
{
    LOG_DEBUG("napi_value <- std::vector<int32_t> ");
    return SetValueArray(env, in, out);
}

/* napi_value <-> std::vector<uint32_t> */
napi_status GetValue(napi_env env, napi_value in, std::vector<uint32_t>& out)
{
    LOG_DEBUG("napi_value -> std::vector<uint32_t> ");
    return GetValueArray(env, in, out);
}

napi_status SetValue(napi_env env, const std::vector<uint32_t>& in, napi_value& out)
{
    LOG_DEBUG("napi_value <- std::vector<uint32_t> ");
    size_t bytes = in.size() * sizeof(uint32_t);
    CHECK_RETURN(bytes > 0, "invalid std::vector<uint32_t>", napi_invalid_arg);
    void* data = nullptr;
    napi_value buffer = nullptr;
    napi_status status = napi_create_arraybuffer(env, bytes, &data, &buffer);
    CHECK_RETURN((status == napi_ok), "invalid buffer", status);

    if (memcpy_s(data, bytes, in.data(), bytes) != EOK) {
        LOG_ERROR("memcpy_s not EOK");
        return napi_invalid_arg;
    }
    status = napi_create_typedarray(env, napi_uint32_array, in.size(), buffer, 0, &out);
    CHECK_RETURN((status == napi_ok), "invalid buffer", status);
    return status;
}

/* napi_value <-> std::vector<int64_t> */
napi_status GetValue(napi_env env, napi_value in, std::vector<int64_t>& out)
{
    LOG_DEBUG("napi_value -> std::vector<int64_t> ");
    return GetValueArray(env, in, out);
}

napi_status SetValue(napi_env env, const std::vector<int64_t>& in, napi_value& out)
{
    LOG_DEBUG("napi_value <- std::vector<int64_t> ");
    size_t bytes = in.size() * sizeof(int64_t);
    CHECK_RETURN(bytes > 0, "invalid std::vector<uint32_t>", napi_invalid_arg);
    void* data = nullptr;
    napi_value buffer = nullptr;
    napi_status status = napi_create_arraybuffer(env, bytes, &data, &buffer);
    CHECK_RETURN((status == napi_ok), "invalid buffer", status);

    if (memcpy_s(data, bytes, in.data(), bytes) != EOK) {
        LOG_ERROR("memcpy_s not EOK");
        return napi_invalid_arg;
    }
    status = napi_create_typedarray(env, napi_bigint64_array, in.size(), buffer, 0, &out);
    CHECK_RETURN((status == napi_ok), "invalid buffer", status);
    return status;
}

napi_status GetValue(napi_env env, napi_value in, CalendarAccount& out)
{
    LOG_DEBUG("napi_value -> CalendarAccount ");
    napi_status status = NapiUtil::GetNamedProperty(env, in, "name", out.name);
    CHECK_RETURN((status == napi_ok), "invalid name", status);
    status = NapiUtil::GetNamedProperty(env, in, "type", out.type);
    CHECK_RETURN((status == napi_ok), "invalid type", status);
    NapiUtil::GetNamedPropertyOptional(env, in, "displayName", out.displayName);
    return napi_ok;
}

napi_status SetValue(napi_env env, const CalendarAccount& in, napi_value& out)
{
    LOG_DEBUG("CalendarAccount -> napi_value ");
    napi_status status = napi_create_object(env, &out);
    CHECK_RETURN((status == napi_ok), "invalid entry object", status);

    napi_value nameValue = nullptr;
    status = SetValue(env, in.name, nameValue);
    CHECK_RETURN((status == napi_ok), "invalid entry name", status);
    napi_set_named_property(env, out, "name", nameValue);
    napi_value typeValue = nullptr;
    status = SetValue(env, in.type, typeValue);
    CHECK_RETURN((status == napi_ok), "invalid entry type", status);
    napi_set_named_property(env, out, "type", typeValue);

    if (in.displayName) {
        napi_value displayNameValue = nullptr;
        status = SetValue(env, in.displayName.value(), displayNameValue);
        CHECK_RETURN((status == napi_ok), "invalid entry displayName", status);
        napi_set_named_property(env, out, "displayName", displayNameValue);
    }
    return status;
}

/* napi_value <-> CalendarConfig */
napi_status GetValue(napi_env env, napi_value in, CalendarConfig& out)
{
    LOG_DEBUG("napi_value -> CalendarConfig ");
    NapiUtil::GetNamedPropertyOptional(env, in, "enableReminder", out.enableReminder);
    NapiUtil::GetNamedPropertyOptional(env, in, "color", out.color);
    return napi_ok;
}

napi_status SetValue(napi_env env, const CalendarConfig& in, napi_value& out)
{
    LOG_DEBUG("CalendarConfig -> napi_value ");
    napi_status status = napi_create_object(env, &out);
    CHECK_RETURN((status == napi_ok), "invalid entry object", status);

    if (in.enableReminder) {
        napi_value enableRemindValue = nullptr;
        status = SetValue(env, in.enableReminder.value(), enableRemindValue);
        CHECK_RETURN((status == napi_ok), "invalid entry enableReminder", status);
        napi_set_named_property(env, out, "enableReminder", enableRemindValue);
    }
    if (in.color) {
        napi_value colorValue = nullptr;
        status = SetValue(env, in.color.value(), colorValue);
        CHECK_RETURN((status == napi_ok), "invalid entry color", status);
        napi_set_named_property(env, out, "color", colorValue);
    }
    return status;
}

napi_status GetValue(napi_env env, napi_value in, Location& out)
{
    LOG_DEBUG("napi_value -> Location ");
    NapiUtil::GetNamedPropertyOptional(env, in, "location", out.location);
    NapiUtil::GetNamedPropertyOptional(env, in, "longitude", out.longitude);
    NapiUtil::GetNamedPropertyOptional(env, in, "latitude", out.latitude);
    return napi_ok;
}

napi_status SetValue(napi_env env, const Location& in, napi_value& out)
{
    LOG_DEBUG("Location -> napi_value ");
    napi_status status = napi_create_object(env, &out);
    CHECK_RETURN((status == napi_ok), "invalid entry object", status);

    if (in.location) {
        napi_value locationValue = nullptr;
        status = SetValue(env, in.location.value(), locationValue);
        CHECK_RETURN((status == napi_ok), "invalid location", status);
        napi_set_named_property(env, out, "location", locationValue);
    }
    if (in.longitude) {
        napi_value value = nullptr;
        status = SetValue(env, in.longitude.value(), value);
        CHECK_RETURN((status == napi_ok), "invalid longitude", status);
        napi_set_named_property(env, out, "longitude", value);
    }
    if (in.latitude) {
        napi_value value = nullptr;
        status = SetValue(env, in.latitude.value(), value);
        CHECK_RETURN((status == napi_ok), "invalid latitude", status);
        napi_set_named_property(env, out, "latitude", value);
    }
    return napi_ok;
}

/* napi_value <-> RecurrenceRule */
napi_status GetValue(napi_env env, napi_value in, RecurrenceRule& out)
{
    LOG_DEBUG("napi_value -> RecurrenceRule ");
    return napi_ok;
}

napi_status SetValue(napi_env env, const RecurrenceRule& in, napi_value& out)
{
    LOG_DEBUG("RecurrenceRule -> napi_value ");
    return napi_ok;
}

/* napi_value <-> Attendee */
napi_status GetValue(napi_env env, napi_value in, Attendee& out)
{
    LOG_DEBUG("Attendee -> napi_value ");
    NapiUtil::GetNamedProperty(env, in, "name", out.name);
    NapiUtil::GetNamedProperty(env, in, "email", out.email);
    return napi_ok;
}

napi_status SetValue(napi_env env, const Attendee& in, napi_value& out)
{
    LOG_DEBUG("napi_value -> Attendee ");
    napi_status status = napi_create_object(env, &out);
    CHECK_RETURN((status == napi_ok), "invalid entry object", status);

    napi_value nameValue = nullptr;
    status = SetValue(env, in.name, nameValue);
    CHECK_RETURN((status == napi_ok), "invalid entry name", status);
    napi_set_named_property(env, out, "name", nameValue);
    napi_value emailValue = nullptr;
    status = SetValue(env, in.email, emailValue);
    CHECK_RETURN((status == napi_ok), "invalid entry type", status);
    napi_set_named_property(env, out, "name", emailValue);
    return napi_ok;
}

/* napi_value <-> std::vector<Attendee> */
napi_status GetValue(napi_env env, napi_value in, std::vector<Attendee>& out)
{
    LOG_DEBUG("napi_value -> std::vector<Attendee> ");
    return GetValueArray(env, in, out);
}

napi_status SetValue(napi_env env, const std::vector<Attendee>& in, napi_value& out)
{
    LOG_DEBUG("std::vector<Attendee> -> napi_value ");
    return SetValueArray(env, in, out);
}

napi_status GetValue(napi_env env, napi_value in, EventService& out)
{
    LOG_DEBUG("napi_value -> EventService");
    NapiUtil::GetNamedPropertyOptional(env, in, "description", out.description);
    NapiUtil::GetNamedProperty(env, in, "type", out.type);
    return NapiUtil::GetNamedProperty(env, in, "uri", out.uri);
}

napi_status SetValue(napi_env env, const EventService& in, napi_value& out)
{
    LOG_DEBUG("EventService -> napi_value");
    napi_status status = napi_create_object(env, &out);
    CHECK_RETURN((status == napi_ok), "invalid entry object", status);

    napi_value typeValue = nullptr;
    status = SetValue(env, in.type, typeValue);
    CHECK_RETURN((status == napi_ok), "invalid typeValue", status);
    status = napi_set_named_property(env, out, "type", typeValue);
    CHECK_RETURN((status == napi_ok), "set type failed", status);

    napi_value uriValue = nullptr;
    status = SetValue(env, in.uri, uriValue);
    CHECK_RETURN((status == napi_ok), "invalid entry type", status);
    status = napi_set_named_property(env, out, "uri", uriValue);
    CHECK_RETURN((status == napi_ok), "set uri failed", status);

    if (in.description) {
        napi_value descriptionValue = nullptr;
        status = SetValue(env, in.description.value(), descriptionValue);
        CHECK_RETURN((status == napi_ok), "invalid description", status);
        status = napi_set_named_property(env, out, "description", descriptionValue);
        CHECK_RETURN((status == napi_ok), "set description failed", status);
    }
    return status;
}

/* napi_value <-> EventFilter */
napi_status GetValue(napi_env env, napi_value in, EventFilterNapi*& out)
{
    LOG_DEBUG("napi_value -> EventFilter ");
    return EventFilterNapi::ToJson(env, in, out);
}

napi_status SetValue(napi_env env, const EventFilterNapi& in, napi_value& out)
{
    LOG_DEBUG("EventFilterNapi -> napi_value ");
    return napi_ok;
}

/* napi_value <-> EventType */
napi_status GetValue(napi_env env, napi_value in, EventType& out)
{
    LOG_DEBUG("napi_value -> EventType ");
    return napi_ok;
}

napi_status SetValue(napi_env env, const EventType& in, napi_value& out)
{
    LOG_DEBUG("EventType -> napi_value ");
    return napi_ok;
}

/* napi_value <-> Event */
napi_status GetValue(napi_env env, napi_value in, Event& out)
{
    LOG_DEBUG("napi_value -> Event ");
    GetNamedPropertyOptional(env, in, "id", out.id);
    int type = -1;
    napi_status status = GetNamedProperty(env, in, "type", type);
    out.type = static_cast<EventType>(type)
    CHECK_RETURN((status == napi_ok), "invalid entry type", status);
    GetNamedPropertyOptional(env, in, "title", out.title);
    GetNamedPropertyOptional(env, in, "location", out.location);
    status = GetNamedProperty(env, in, "startTime", out.startTime);
    CHECK_RETURN((status == napi_ok), "invalid entry startTime", status);
    status = GetNamedProperty(env, in, "endTime", out.endTime);
    CHECK_RETURN((status == napi_ok), "invalid entry endTime", status);
    GetNamedPropertyOptional(env, in, "isAllDay", out.isAllDay);
    GetNamedProperty(env, in, "attendee", out.attendees); // colud be empty not check result
    GetNamedPropertyOptional(env, in, "timeZone", out.timeZone);
    GetNamedPropertyOptional(env, in, "reminderTime", out.reminderTime);
    GetNamedPropertyOptional(env, in, "recurrenceRule", out.recurrenceRule);
    GetNamedPropertyOptional(env, in, "description", out.description);
    GetNamedPropertyOptional(env, in, "service", out.service);
    Native::DumpEvent(out);
    return status;
}

napi_status SetValue(napi_env env, const Event& in, napi_value& out)
{
    LOG_DEBUG("Event -> napi_value");
    napi_status status = napi_create_object(env, &out);
    CHECK_RETURN((status == napi_ok), "invalid entry object", status);

    napi_value id = nullptr;
    status = SetValue(env, in.id.value(), id);
    CHECK_RETURN((status == napi_ok), "invalid entry id", status);
    napi_set_named_property(env, out, "id", id);

    napi_value type = nullptr;
    status = SetValue(env, static_cast<int>(in.type), type);
    CHECK_RETURN((status == napi_ok), "invalid entry type", status);
    napi_set_named_property(env, out, "type", type);

    napi_value startTime = nullptr;
    status = SetValue(env, in.startTime, startTime);
    CHECK_RETURN((status == napi_ok), "invalid entry startTime", status);
    napi_set_named_property(env, out, "startTime", startTime);

    napi_value endTime = nullptr;
    status = SetValue(env, in.endTime, endTime);
    CHECK_RETURN((status == napi_ok), "invalid entry endTime", status);
    napi_set_named_property(env, out, "endTime", endTime);

    if (!in.attendees.empty()) {
        napi_value attendees = nullptr;
        status = SetValue(env, in.attendees, attendees);
        CHECK_RETURN((status == napi_ok), "invalid entry attendees", status);
        napi_set_named_property(env, out, "attendees", attendees);
    }

    if (in.title) {
        napi_value titleValue = nullptr;
        status = SetValue(env, in.title.value(), titleValue);
        CHECK_RETURN((status == napi_ok), "invalid entry title", status);
        napi_set_named_property(env, out, "title", titleValue);
    }
    if (in.location) {
        napi_value value = nullptr;
        status = SetValue(env, in.location.value(), value);
        CHECK_RETURN((status == napi_ok), "invalid location", status);
        napi_set_named_property(env, out, "location", value);
    }
    if (in.service) {
        napi_value value = nullptr;
        status = SetValue(env, in.service.value(), value);
        CHECK_RETURN((status == napi_ok), "invalid service", status);
        napi_set_named_property(env, out, "service", value);
    }

    if (in.reminderTime) {
        napi_value value = nullptr;
        status = SetValue(env, in.reminderTime.value(), value);
        CHECK_RETURN((status == napi_ok), "invalid entry reminderTime", status);
        napi_set_named_property(env, out, "reminderTime", value);
    }
    return status;
}

/* napi_value <-> std::vector<Event> */
napi_status GetValue(napi_env env, napi_value in, std::vector<Event>& out)
{
    LOG_DEBUG("napi_value -> std::vector<Event>");
    return GetValueArray(env, in, out);
}

napi_status SetValue(napi_env env, const std::vector<Event>& in, napi_value& out)
{
    LOG_DEBUG("std::vector<Event> -> napi_value");
    return SetValueArray(env, in, out);
}


napi_value DefineClass(napi_env env, const std::string& name,
    const napi_property_descriptor* properties, size_t count, napi_callback newcb)
{
    // base64("calendar.calendarmanager") as rootPropName, i.e. global.<root>
    const std::string rootPropName = "Y2FsZW5kYXIuY2FsZW5kYXJtYW5hZ2Vy";
    napi_value root = nullptr;
    bool hasRoot = false;
    napi_value global = nullptr;
    napi_get_global(env, &global);
    napi_has_named_property(env, global, rootPropName.c_str(), &hasRoot);
    if (hasRoot) {
        napi_get_named_property(env, global, rootPropName.c_str(), &root);
    } else {
        napi_create_object(env, &root);
        napi_set_named_property(env, global, rootPropName.c_str(), root);
    }

    std::string propName = "constructor_of_" + name;
    napi_value constructor = nullptr;
    bool hasProp = false;
    napi_has_named_property(env, root, propName.c_str(), &hasProp);
    if (hasProp) {
        napi_get_named_property(env, root, propName.c_str(), &constructor);
        if (constructor != nullptr) {
            LOG_DEBUG("got calendar.calendarmanager.%{public}s as constructor", propName.c_str());
            return constructor;
        }
        hasProp = false; // no constructor.
    }

    NAPI_CALL(env, napi_define_class(env, name.c_str(), name.size(), newcb, nullptr, count, properties, &constructor));
    NAPI_ASSERT(env, constructor != nullptr, "napi_define_class failed!");

    if (!hasProp) {
        napi_set_named_property(env, root, propName.c_str(), constructor);
        LOG_DEBUG("save constructor to calendar.calendarmanager.%{public}s", propName.c_str());
    }
    return constructor;
}

napi_ref NewWithRef(napi_env env, size_t argc, napi_value* argv, void** out, napi_value constructor)
{
    napi_value object = nullptr;
    napi_status status = napi_new_instance(env, constructor, argc, argv, &object);
    CHECK_RETURN(status == napi_ok, "napi_new_instance failed", nullptr);
    CHECK_RETURN(object != nullptr, "napi_new_instance failed", nullptr);

    status = napi_unwrap(env, object, out);
    CHECK_RETURN(status == napi_ok, "napi_unwrap failed", nullptr);
    CHECK_RETURN(out != nullptr, "napi_unwrap failed", nullptr);

    napi_ref ref = nullptr;
    status = napi_create_reference(env, object, 1, &ref);
    CHECK_RETURN(status == napi_ok, "napi_create_referenc!e failed", nullptr);
    CHECK_RETURN(ref != nullptr, "napi_create_referenc!e failed", nullptr);
    return ref;
}

napi_status Unwrap(napi_env env, napi_value in, void** out, napi_value constructor)
{
    if (constructor != nullptr) {
        bool isInstance = false;
        auto status = napi_instanceof(env, in, constructor, &isInstance);
        if (status != napi_ok) {
            LOG_ERROR("napi_instanceof failed");
            return status;
        }
        if (!isInstance) {
            LOG_ERROR("not a instance of *");
            return napi_invalid_arg;
        }
    }
    return napi_unwrap(env, in, out);
}

bool Equals(napi_env env, napi_value value, napi_ref copy)
{
    if (copy == nullptr) {
        return (value == nullptr);
    }

    napi_value copyValue = nullptr;
    napi_get_reference_value(env, copy, &copyValue);

    bool isEquals = false;
    napi_strict_equals(env, value, copyValue, &isEquals);
    return isEquals;
}

} // namespace OHOS::DistributedData
