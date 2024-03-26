type HronRequest = {
    method: HronRequestMethod
    url: HronRequestUrl    
    query: Array<HronRequestQuery>
    headers: Array<HronRequestHeader>
    cookies: Array<HronRequestCookie>
    body: HronRequestBody
    params: Array<HronRequestParam>
}
type HronRequestUrl = `${HronRequestProtocol}://${HronRequestHost}:${HronRequestPort}${HronRequestPath}${HronRequestSearch}${HronRequestHash}`
type HronRequestProtocol = 'http' | 'https'
type HronRequestPort = 80 | 443 | number
type HronRequestPath = string
type HronRequestUser = string
type HronRequestPassword = string
type HronRequestHost = string
type HronRequestHostname = string
type HronRequestHash = string
type HronRequestSearch = string
type HronRequestCredentials = `${HronRequestUser}:${HronRequestPassword}`

type HronRequestParam = {
    type: HronRequestParamType
    name: string
    description: string
    defaultValue: string
    required: boolean
    input: HronRequestParamInput
}
type HronRequestParamInput = {
    prompt: string
    placeholder: string
    variable: string
    argv: string
    options: Array<string>
    multiple: boolean
    min: number    
    max: number
    regex: string
    pattern: string
    format: string
    minDate: string
    maxDate: string
    minTime: string
    maxTime: string
    minDateTime: string
    maxDateTime: string
    minYear: number    
}
type HronRequestParamType = 'string' | 'number' | 'boolean' | 'array' | 'object'
type HronRequestMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD' | 'OPTIONS' | 'CONNECT' | 'TRACE'
type HronRequestQuery = {
    key: string
    value: string
}
type HronRequestBody = {
    mode: HronRequestBodyMode
    raw: string
    formdata?: Array<HronRequestFormdata>
    urlencoded?: Array<HronRequestUrlencoded>
    file?: Array<HronRequestFile>
}
type HronRequestBodyMode = 'raw' | 'formdata' | 'urlencoded' | 'file'
type HronRequestFormdata = {
    key: string
    value: string
    type: string
}
type HronRequestUrlencoded = {
    key: string
    value: string
}
type HronRequestFile = {
    src: string
    content: string
    type: string
}
type HronRequestHeader = {
    key: string
    value: string
}
type HronRequestCookie = {
    name: string
    value: string
    domain?: string
    path?: string
    expires?: number
    size?: number
    httpOnly?: boolean
    secure?: boolean
    session?: boolean    
}