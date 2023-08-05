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
    out.clear();
    bool isArray = false;
    napi_is_array(env, in, &isArray);
    CHECK_RETURN(isArray, "not an array", napi_invalid_arg);

    uint32_t length = 0;
    napi_status status = napi_get_array_length(env, in, &length);
    CHECK_RETURN((status == napi_ok) && (length > 0), "get_array failed!", napi_invalid_arg);
    for (uint32_t i = 0; i < length; ++i) {
        napi_value item = nullptr;
        status = napi_get_element(env, in, i, &item);
        CHECK_RETURN((item != nullptr) && (status == napi_ok), "no element", napi_invalid_arg);
        std::string value;
        status = GetValue(env, item, value);
        CHECK_RETURN(status == napi_ok, "not a string", napi_invalid_arg);
        out.push_back(value);
    }
    return status;
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

template <typename T>
void TypedArray2Vector(uint8_t* data, size_t length, napi_typedarray_type type, std::vector<T>& out)
{
    auto convert = [&out](auto* data, size_t elements) {
        for (size_t index = 0; index < elements; index++) {
            out.push_back(static_cast<T>(data[index]));
        }
    };

    switch (type) {
        case napi_int8_array:
            convert(reinterpret_cast<int8_t*>(data), length);
            break;
        case napi_uint8_array:
            convert(data, length);
            break;
        case napi_uint8_clamped_array:
            convert(data, length);
            break;
        case napi_int16_array:
            convert(reinterpret_cast<int16_t*>(data), length / sizeof(int16_t));
            break;
        case napi_uint16_array:
            convert(reinterpret_cast<uint16_t*>(data), length / sizeof(uint16_t));
            break;
        case napi_int32_array:
            convert(reinterpret_cast<int32_t*>(data), length / sizeof(int32_t));
            break;
        case napi_uint32_array:
            convert(reinterpret_cast<uint32_t*>(data), length / sizeof(uint32_t));
            break;
        case napi_float32_array:
            convert(reinterpret_cast<float*>(data), length / sizeof(float));
            break;
        case napi_float64_array:
            convert(reinterpret_cast<double*>(data), length / sizeof(double));
            break;
        case napi_bigint64_array:
            convert(reinterpret_cast<int64_t*>(data), length / sizeof(int64_t));
            break;
        case napi_biguint64_array:
            convert(reinterpret_cast<uint64_t*>(data), length / sizeof(uint64_t));
            break;
        default:
            CHECK_RETURN_VOID(false, "[FATAL] invalid napi_typedarray_type!");
    }
}

/* napi_value <-> std::vector<int32_t> */
napi_status GetValue(napi_env env, napi_value in, std::vector<int32_t>& out)
{
    out.clear();
    LOG_DEBUG("napi_value -> std::vector<int32_t> ");
    napi_typedarray_type type = napi_biguint64_array;
    size_t length = 0;
    napi_value buffer = nullptr;
    size_t offset = 0;
    uint8_t* data = nullptr;
    napi_status status = napi_get_typedarray_info(env, in, &type, &length,
                                                  reinterpret_cast<void**>(&data), &buffer, &offset);
    LOG_DEBUG("array type=%{public}d length=%{public}d offset=%{public}d", (int)type, (int)length, (int)offset);
    CHECK_RETURN(status == napi_ok, "napi_get_typedarray_info failed!", napi_invalid_arg);
    CHECK_RETURN(type <= napi_int32_array, "is not int32 supported typed array!", napi_invalid_arg);
    CHECK_RETURN((length > 0) && (data != nullptr), "invalid data!", napi_invalid_arg);
    TypedArray2Vector<int32_t>(data, length, type, out);
    return status;
}

napi_status SetValue(napi_env env, const std::vector<int32_t>& in, napi_value& out)
{
    LOG_DEBUG("napi_value <- std::vector<int32_t> ");
    size_t bytes = in.size() * sizeof(int32_t);
    CHECK_RETURN(bytes > 0, "invalid std::vector<int32_t>", napi_invalid_arg);
    void* data = nullptr;
    napi_value buffer = nullptr;
    napi_status status = napi_create_arraybuffer(env, bytes, &data, &buffer);
    CHECK_RETURN((status == napi_ok), "invalid buffer", status);

    if (memcpy_s(data, bytes, in.data(), bytes) != EOK) {
        LOG_ERROR("memcpy_s not EOK");
        return napi_invalid_arg;
    }
    status = napi_create_typedarray(env, napi_int32_array, in.size(), buffer, 0, &out);
    CHECK_RETURN((status == napi_ok), "invalid buffer", status);
    return status;
}

/* napi_value <-> std::vector<uint32_t> */
napi_status GetValue(napi_env env, napi_value in, std::vector<uint32_t>& out)
{
    out.clear();
    LOG_DEBUG("napi_value -> std::vector<uint32_t> ");
    napi_typedarray_type type = napi_biguint64_array;
    size_t length = 0;
    napi_value buffer = nullptr;
    size_t offset = 0;
    uint8_t* data = nullptr;
    napi_status status = napi_get_typedarray_info(env, in, &type, &length,
                                                  reinterpret_cast<void**>(&data), &buffer, &offset);
    LOG_DEBUG("napi_get_typedarray_info type=%{public}d", (int)type);
    CHECK_RETURN(status == napi_ok, "napi_get_typedarray_info failed!", napi_invalid_arg);
    CHECK_RETURN((type <= napi_uint16_array) || (type == napi_uint32_array), "invalid type!", napi_invalid_arg);
    CHECK_RETURN((length > 0) && (data != nullptr), "invalid data!", napi_invalid_arg);
    TypedArray2Vector<uint32_t>(data, length, type, out);
    return status;
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
    out.clear();
    LOG_DEBUG("napi_value -> std::vector<int64_t> ");
    napi_typedarray_type type = napi_biguint64_array;
    size_t length = 0;
    napi_value buffer = nullptr;
    size_t offset = 0;
    uint8_t* data = nullptr;
    napi_status status = napi_get_typedarray_info(env, in, &type, &length,
                                                  reinterpret_cast<void**>(&data), &buffer, &offset);
    LOG_DEBUG("array type=%{public}d length=%{public}d offset=%{public}d", (int)type, (int)length, (int)offset);
    CHECK_RETURN(status == napi_ok, "napi_get_typedarray_info failed!", napi_invalid_arg);
    CHECK_RETURN((type <= napi_uint32_array) || (type == napi_bigint64_array), "invalid type!", napi_invalid_arg);
    CHECK_RETURN((length > 0) && (data != nullptr), "invalid data!", napi_invalid_arg);
    TypedArray2Vector<int64_t>(data, length, type, out);
    return status;
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
    if (status != napi_ok) {
        return status;
    }
    NapiUtil::GetNamedProperty(env, in, "type", out.type);
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
    return napi_ok;
}

napi_status SetValue(napi_env env, const Location& in, napi_value& out)
{
    LOG_DEBUG("Location -> napi_value ");
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


/* napi_value <-> EventService */
napi_status GetValue(napi_env env, napi_value in, EventService& out)
{
    LOG_DEBUG("EventService -> napi_value ");
    return napi_ok;
}
napi_status SetValue(napi_env env, const EventService& in, napi_value& out)
{
    LOG_DEBUG("napi_value -> EventService ");
    return napi_ok;
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
    napi_status status = GetNamedProperty(env, in, "type", out.type);
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
    status = SetValue(env, in.type, type);
    CHECK_RETURN((status == napi_ok), "invalid entry type", status);
    napi_set_named_property(env, out, "type", type);

    if (in.title) {
        napi_value titleValue = nullptr;
        status = SetValue(env, in.title.value(), titleValue);
        CHECK_RETURN((status == napi_ok), "invalid entry title", status);
        napi_set_named_property(env, out, "title", titleValue);
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
