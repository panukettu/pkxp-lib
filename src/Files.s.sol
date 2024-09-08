// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {wm} from "./Wm.s.sol";
import {Nope} from "./Misc.sol";

struct File {
    string loc;
}

using Files for File global;

library Files {
    string internal constant DEFAULT_FOLDER = "temp";

    function ensureDir(string memory path) internal {
        if (!wm.vm().exists(path)) {
            wm.vm().createDir(path, true);
            wm.vm().removeDir(path, false);
        }
    }

    function defaultPath(
        string memory fileName
    ) internal pure returns (string memory) {
        return string.concat(DEFAULT_FOLDER, "/", fileName);
    }

    function file(string memory loc) internal pure returns (File memory) {
        return File(loc);
    }

    function exists(File memory f) internal returns (bool) {
        return wm.vm().exists(f.loc);
    }

    function ensure(File memory f) internal returns (File memory) {
        if (!f.exists()) revert Nope(string.concat("file.ensure: ", f.loc));
        return f;
    }

    function write(
        string memory path,
        bytes memory data
    ) internal returns (File memory) {
        ensureDir(path);
        wm.vm().writeFile(path, trim(data));
        wm.store().files.push(path);
        return File(path);
    }
    function write(
        bytes memory data,
        string memory fileName
    ) internal returns (File memory) {
        return write(defaultPath(fileName), data);
    }

    function write(
        File memory f,
        bytes memory data
    ) internal returns (File memory) {
        wm.vm().writeFile(f.loc, trim(data));
        return f;
    }

    function write(bytes memory data) internal returns (File memory) {
        return write(wm.vm().toString(wm.id4()), data);
    }

    function read(string memory loc) internal returns (bytes memory) {
        return wm.vm().parseBytes(wm.vm().trim(wm.vm().readFile(loc)));
    }

    function read(File memory f) internal returns (bytes memory) {
        return read(f.loc);
    }

    function append(
        File memory f,
        bytes memory data
    ) internal returns (File memory) {
        write(f.loc, bytes.concat(f.flush(), data));
        return f;
    }

    function flush(File memory f) internal returns (bytes memory d) {
        return flush(f.loc);
    }

    function flush(string memory loc) internal returns (bytes memory d) {
        if (bytes(loc).length == 0) revert("no last id");
        d = read(loc);
        write(loc, "");
    }

    function rm(File memory f) internal returns (File memory) {
        return rm(f.loc);
    }

    function rm(string memory loc) internal returns (File memory) {
        if (File(loc).exists()) wm.vm().removeFile(loc);
        return File(loc);
    }

    function clear() internal {
        for (uint256 i; i < wm.store().files.length; i++) {
            File(wm.store().files[i]).rm();
        }
        delete wm.store().files;
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

    function clg() internal {
        for (uint256 i; i < wm.store().files.length; i++) {
            clg(File(wm.store().files[i]));
        }
    }

    function trim(bytes memory _s) internal pure returns (string memory) {
        return wm.vm().trim(wm.vm().toString(_s));
    }
}
