using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PowerBIReleaseTool.Services
{
    using System.Threading;
    using Newtonsoft.Json;

    public interface IGitHubService
    {
        String GithubApiUrl { get; }
        Task UpdateRelease(String releaseId, String releaseBody, CancellationToken cancellationToken);

        Task<GitHubReleaseDTO> GetRelease(String tag,
                                          CancellationToken cancellationToken);

        Task<String> GetReleaseAsset(Int32 assetId,
                                     String assetName,
                                     String outputPath, 
                                     CancellationToken cancellationToken);

        Task<List<GitHubReleaseDTO>> GetReleases(CancellationToken cancellationToken);
    }

    public class GitHubReleaseDTO
    {
        [JsonProperty("id")]
        public Int32 Id { get; set; }

        [JsonProperty("body")]
        public String Body { get; set; }

        [JsonProperty("tag_name")]
        public String Tag { get; set; }

        [JsonProperty("assets")]
        public List<GithubReleaseAsset> Assets { get; set; }
    }

    public class GithubReleaseAsset
    {
        [JsonProperty("id")]
        public Int32 Id { get; set; }

        [JsonProperty("name")]
        public String Name { get; set; }
    }
}
