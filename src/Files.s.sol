// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {wm} from "./Wm.s.sol";
import {Help} from "./Help.s.sol";
import {Nope, map} from "./Misc.sol";

struct File {
    string loc;
}

using Files for File global;

library Files {
    string internal constant DEFAULT_FOLDER = "temp";

    using Help for *;

    function ensureDir(string memory loc) internal returns (string memory) {
        if (!wm.vm().exists(loc)) {
            wm.vm().createDir(loc, true);
            wm.vm().removeDir(loc, false);
        }

        return loc;
    }

    function defaultPath(
        string memory name
    ) internal pure returns (string memory) {
        return string.concat(DEFAULT_FOLDER, "/", name);
    }

    function file(string memory loc) internal pure returns (File memory) {
        return File(loc);
    }

    function exists(File memory f) internal returns (bool) {
        return wm.vm().exists(f.loc);
    }

    function ensure(File memory f) internal returns (File memory r) {
        if (!(r = f).exists())
            revert Nope(string.concat("file.ensure: ", f.loc));
    }

    function write(
        string memory loc,
        bytes memory d
    ) internal returns (File memory) {
        ensureDir(loc);
        wm.vm().writeFile(loc, d.trim());
        wm.store().files.push(loc);
        return File(loc);
    }

    function write(
        bytes memory d,
        string memory name
    ) internal returns (File memory) {
        return write(defaultPath(name), d);
    }

    function write(
        File memory f,
        bytes memory d
    ) internal returns (File memory) {
        return write(f.loc, d);
    }

    function write(bytes memory d) internal returns (File memory) {
        return write(wm.fileId().str(), d);
    }

    function read(string memory loc) internal returns (bytes memory) {
        return wm.vm().readFile(loc).trim().bts();
    }

    function read(File memory f) internal returns (bytes memory) {
        return read(f.loc);
    }

    function append(
        File memory f,
        bytes memory d
    ) internal returns (File memory) {
        return write(f.loc, f.flush().concat(d));
    }

    function flush(File memory f) internal returns (bytes memory d) {
        return flush(f.loc);
    }

    function flush(string memory loc) internal returns (bytes memory d) {
        if (bytes(loc).length == 0) revert Nope("file.flush: empty loc");
        d = read(loc);
        write(loc, "");
    }

    function del(File memory f) internal returns (File memory) {
        return rm(f.loc);
    }

    function rm(string memory loc) internal returns (File memory) {
        if (File(loc).exists()) wm.vm().removeFile(loc);
        return File(loc);
    }

    function clear() internal returns (uint256 len) {
        string[] storage files = wm.store().files;
        len = files.length;

        map(files, rm);
        delete wm.store().files;
    }

    function get() internal returns (File[] memory) {
        return map(wm.store().files, file);
    }

    /* ------------------------------------ . ----------------------------------- */

    function clg(File memory f) internal returns (File memory) {
        wm.clg(
            string.concat(
                "\n     path: ",
                f.loc,
                "\n     data: ",
                wm.vm().toString(f.read())
            )
        );
        return f;
    }
}
