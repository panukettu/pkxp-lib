// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Help} from "./Help.s.sol";

struct Time {
    uint256 sepoch;
    uint256 year;
    uint256 month;
    uint256 day;
    uint256 hour;
    uint256 minute;
    uint256 second;
    string str;
}

using Times for Time global;

library Times {
    using Help for uint256;
    using Help for string;
    function toApproxDate(
        uint256 sepoch
    ) internal pure returns (Time memory time) {
        if (sepoch == 0) {
            time.str = "N/A";
            return time;
        }

        time.sepoch = sepoch;
        time.year = 1970 + sepoch / 31556952;
        time.month = ((sepoch % 31556952) / 2629746) + 1;
        time.day = ((sepoch % 2629746) / 86400) + 1;
        time.hour = (sepoch % 86400) / 3600;
        time.minute = (sepoch % 3600) / 60;
        time.second = sepoch % 60;

        if (time.month > 12) {
            time.month = time.month - 12;
            time.year++;
        }

        uint256 monthDays = daysInMonth(time.year, time.month);

        if (time.day > monthDays) {
            time.day = time.day - monthDays;
            time.month++;
            if (time.month > 12) {
                time.month = time.month - 12;
                time.year++;
            }
        }

        time.str = string.concat(
            str(time.year),
            "-",
            str(time.month),
            "-",
            str(time.day),
            "T",
            str(time.hour),
            ":",
            str(time.minute),
            ":",
            str(time.second)
        );
    }

    function str(uint256 value) internal pure returns (string memory) {
        return value.str().padLeft(2, "0");
    }

    function daysInMonth(
        uint256 year,
        uint256 month
    ) internal pure returns (uint256) {
        return daysInMonth(year)[month - 1];
    }

    function daysInMonth(
        uint256 year
    ) internal pure returns (uint256[12] memory) {
        bool leap = year % 4 == 0;
        return [
            uint256(31),
            leap ? 29 : 28,
            31,
            30,
            31,
            30,
            31,
            31,
            30,
            31,
            30,
            31
        ];
    }

    function getRelativeTime(
        Time memory past,
        Time memory present
    ) internal pure returns (Time memory) {
        return getRelativeTime(past.sepoch, present.sepoch);
    }
    function getRelativeTime(
        Time memory past,
        uint256 present
    ) internal pure returns (Time memory) {
        return getRelativeTime(past.sepoch, present);
    }

    function getRelativeTime(
        uint256 past,
        uint256 present
    ) internal pure returns (Time memory result) {
        if (present < past) {
            result.str = "N/A";
            return result;
        }

        uint256 diff = present - past;

        result.minute = diff > 60 ? diff / 60 : 0;
        result.hour = diff > 3600 ? diff / 3600 : 0;
        result.day = diff > 86400 ? diff / 86400 : 0;
        result.month = diff > 2629746 ? diff / 2629746 : 0;
        result.year = diff > 31556952 ? diff / 31556952 : 0;
        result.second = diff;
        result.str = getRelativeTimeString(past, present);
    }

    function getRelativeTimeString(
        Time memory past,
        Time memory present
    ) internal pure returns (string memory) {
        return getRelativeTimeString(past.sepoch, present.sepoch);
    }
    function getRelativeTimeString(
        Time memory past,
        uint256 present
    ) internal pure returns (string memory) {
        return getRelativeTimeString(past.sepoch, present);
    }

    function getRelativeTimeString(
        uint256 past,
        uint256 present
    ) internal pure returns (string memory) {
        if (present < past) return "N/A";

        uint256 diff = present - past;
        if (diff < 60) return "just now";

        uint256 result;
        string memory suffix;

        if (diff < 3600) {
            result = diff / 60;
            suffix = "m ago";
        } else if (diff < 86400) {
            result = diff / 3600;
            suffix = "h ago";
        } else if (diff < 604800) {
            result = diff / 86400;
            suffix = "d ago";
        } else {
            result = diff / 604800;
            suffix = "w ago";
        }

        return result.str().concat(suffix);
    }
}
