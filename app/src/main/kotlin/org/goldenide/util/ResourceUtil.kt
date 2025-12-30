/*
 * This file is part of Golden IDE.
 * Golden IDE is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 * Golden IDE is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with Golden IDE. If not, see <https://www.gnu.org/licenses/>.
 */

package com.github.scto.goldenide.util

import com.github.scto.goldenide.rewrite.util.FileUtil

object ResourceUtil {

    val resources =
        arrayOf("index.json")

    fun missingResources(): List<String> {
        val missing = mutableListOf<String>()
        for (resource in resources) {
            val file = FileUtil.dataDir.resolve(resource)
            if (!file.exists()) {
                missing.add(resource)
            }
        }
        return missing
    }
}
