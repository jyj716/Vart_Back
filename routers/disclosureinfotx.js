/*
 * SPDX-License-Identifier: Apache-2.0
 */

const readDisclosure = async (request) => {
    let readData = await request.contract.evaluateTransaction(
        'readDisclosure',
        request.no,
    );

    result = {
        result: true,
        data: readData
    }

    return result
}


const addDisclosure = async (request) => {
    try {
        await request.contract.submitTransaction(
            "addDisclosure",
            request.disclosure.no,
            request.disclosure.reportTitle,
            new Date().toISOString().substring(0, 10),
            request.disclosure.type,
            request.disclosure.applicableDate,
            request.disclosure.details,
            request.disclosure.token
        );

        return true

    } catch (error) {
        console.error(`Failed to submit transaction: ${error}`)

        return false
    }
}

const readAllDisclosure = async (request) => {
    const readData = await request.contract.evaluateTransaction('readAllDisclosure');

    var result = {
        result: true,
        data: readData
    }

    return result
}

const updateDisclosure = async (request) => {
    try {
        await request.contract.submitTransaction(
            "updateDisclosure",
            request.recentinfo.no,
            request.recentinfo.reportTitle,
            new Date().toISOString().substring(0, 10),
            request.recentinfo.type,
            request.recentinfo.applicableDate,
            request.recentinfo.details,
            request.recentinfo.token
        );

        return true

    } catch (error) {
        console.error(`Failed to submit transaction: ${error}`)

        return false
    }
}



module.exports = {
    readAllDisclosure,
    addDisclosure,
    readDisclosure,
    updateDisclosure
};
