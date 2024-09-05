async function handler(event) {
    const request = event.request;
    const host = request.headers.host && request.headers.host.value;
    const uri = request.uri;

    if (typeof host === "string" && host.indexOf('stehefan.de') !== -1) {

        const newHost = host.replace('stehefan.de', 'stefanlier.de');

        return {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: {
                'location': {'value': `https://${newHost}${uri}`}
            }
        };
    }

    return request;
}