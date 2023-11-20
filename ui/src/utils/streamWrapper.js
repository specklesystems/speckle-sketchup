require('url')

export class StreamWrapper {
    constructor(streamIdOrUrl, accountId, serverUrl, isFE2) {
        this.isFE2 = isFE2
        this.streamsKey = this.isFE2 ? 'projects/': 'streams/'
        this.branchesKey = this.isFE2 ? 'models/': 'branches/'
        this.commitsKey = this.isFE2 ? 'versions/': 'commits/'
        this.originalOutput = streamIdOrUrl
        try {
            this.streamWrapperFromUrl(streamIdOrUrl)
        }
        catch (e){
            this.serverUrl = serverUrl
            this.userId = accountId
            this.streamId = streamIdOrUrl
        }
    }

    streamWrapperFromUrl(streamUrl){
        this.url = new URL(streamUrl)
        this.segments = this.url.pathname.split('/').map((segment) => segment + '/')
        this.serverUrl = this.url.origin

        if (this.segments.length >= 4 && this.segments[3]?.toLowerCase() === this.branchesKey){
            this.streamId = this.segments[2].replace("/", "")
            if (this.segments.length > 5)
            {
                let branchSegments = this.segments.slice(4, this.segments.length - 1);
                this.branchName = branchSegments.join("")
            }
            else
            {
                this.branchName = this.segments[4]
            }
        } else {
            switch (this.segments.length){
                case 3: // ie http://speckle.server/streams/8fecc9aa6d
                    if (this.segments[1].toLowerCase() === this.streamsKey)
                        this.streamId = this.segments[2].replace("/", "");
                    else
                        throw new Error(`Cannot parse ${this.originalOutput} into a stream wrapper class`);
                    break;
                case 4: // ie https://speckle.server/streams/0c6ad366c4/globals/
                    if (this.segments[3].toLowerCase().startsWith("globals"))
                    {
                        this.streamId = this.segments[2].replace("/", "");
                        this.branchName = this.segments[3].replace("/", "");
                    }
                    else
                        throw new Error(`Cannot parse ${this.originalOutput} into a stream wrapper class`);
                    break;
                case 5: // ie http://speckle.server/streams/8fecc9aa6d/commits/76a23d7179
                    switch (this.segments[3].toLowerCase()){
                        case this.commitsKey:
                            this.streamId = this.segments[2].replace("/", "");
                            this.commitId = this.segments[4].replace("/", "");
                            break;
                        case "globals/":
                            this.streamId = this.segments[2].replace("/", "");
                            this.branchName = this.segments[3].replace("/", "");
                            this.commitId = this.segments[4].replace("/", "");
                            break;
                        case this.branchesKey:
                            this.streamId = this.segments[2].replace("/", "");
                            this.branchName = this.segments[4].replace("/", "");
                            break;
                        case "objects/":
                            this.streamId = this.segments[2].replace("/", "");
                            this.objectId = this.segments[4].replace("/", "");
                            break;
                        default:
                            throw new Error(`Cannot parse ${this.originalOutput} into a stream wrapper class`);
                    }
                    break;
                default:
                    throw new Error(`Cannot parse ${this.originalOutput} into a stream wrapper class`);
            }
        }
    }
}