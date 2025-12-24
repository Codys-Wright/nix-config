# WebApps configuration - Site-specific browser instances
{...}: {
  cody.webapps.homeManager = {...}: {
    programs.firefox.webapps = {
      # YouTube
      youtube = {
        url = "https://youtube.com";
        id = 1;
        name = "YouTube";
        icon = "youtube";
        categories = ["AudioVideo" "Video"];
        theme = "dark";
      };

      # ChatGPT
      chatgpt = {
        url = "https://chatgpt.com";
        id = 2;
        name = "ChatGPT";
        icon = "chatgpt";
        categories = ["Office" "Utility"];
        theme = "dark";
      };

      # Gmail
      gmail = {
        url = "https://gmail.com";
        id = 3;
        name = "Gmail";
        icon = "gmail";
        categories = ["Office" "Email"];
        theme = "light";
      };
    };
  };
}
