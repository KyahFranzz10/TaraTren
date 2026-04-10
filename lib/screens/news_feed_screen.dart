import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _lines = ['LRT-1', 'LRT-2', 'MRT-3', 'PNR'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _lines.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FE),
      child: Column(
        children: [
          // Development Note / Beta Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border(bottom: BorderSide(color: Colors.amber.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.new_releases,
                    color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Note: The real-time Facebook sync is currently in Beta. Features may not be fully functional as we refine sync accuracy.",
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0D1B3E),
              unselectedLabelColor: Colors.grey.shade400,
              indicatorColor: Colors.orange,
              indicatorWeight: 4,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: _lines.map((name) => Tab(text: name)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children:
                  _lines.map((line) => _ScrapedFeedList(line: line)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrapedFeedList extends StatefulWidget {
  final String line;
  const _ScrapedFeedList({required this.line});

  @override
  State<_ScrapedFeedList> createState() => _ScrapedFeedListState();
}

class _ScrapedFeedListState extends State<_ScrapedFeedList> {
  late final WebViewController _webController;
  List<dynamic> _scrapedPosts = [];
  bool _isLoading = true;
  bool _hasError = false;

  final Map<String, String> _fbUrls = {
    'LRT-1': 'https://www.facebook.com/officialLRT1',
    'LRT-2': 'https://www.facebook.com/OfficialLRTA',
    'MRT-3': 'https://www.facebook.com/dotrmrt3',
    'PNR': 'https://www.facebook.com/officialpnrpage',
  };

  @override
  void initState() {
    super.initState();
    _initScraper();
  }

  void _initScraper() {
    final pageUrl = _fbUrls[widget.line]!;
    final pluginUrl =
        "https://www.facebook.com/plugins/page.php?href=${Uri.encodeComponent(pageUrl)}&tabs=timeline&width=500&height=2500&small_header=true&adapt_container_width=true&hide_cover=true&show_facepile=false&hide_cta=true";

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36")
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            Future.delayed(const Duration(milliseconds: 1500), _scrapeData);
            Future.delayed(const Duration(milliseconds: 3000), _scrapeData);
          },
        ),
      )
      ..addJavaScriptChannel(
        'LRT_Scraper',
        onMessageReceived: (message) {
          try {
            final List<dynamic> data = jsonDecode(message.message);
            if (data.isNotEmpty && mounted) {
              setState(() {
                _scrapedPosts = data;
                _isLoading = false;
                _hasError = false;
              });
              _checkAndNotifyAdvisories(data);
            }
          } catch (e) {
            debugPrint("Scrape Parse Error: $e");
          }
        },
      )
      ..loadRequest(Uri.parse(pluginUrl));

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isLoading) _scrapeData();
    });
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          if (_scrapedPosts.isEmpty) _hasError = true;
        });
      }
    });
  }

  Future<void> _checkAndNotifyAdvisories(List<dynamic> posts) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifiedPosts = prefs.getStringList('notified_advisories') ?? [];
    
    final keywords = [
      "technical issue",
      "limited operations",
      "resumes full operations",
      "customer advisory",
      "dotr-mrt-3 advisory",
      "lrtadvisory"
    ];

    bool hasNewAdvisory = false;

    for (var post in posts) {
      final String contentOrig = post['content'].toString();
      final String contentLow = contentOrig.toLowerCase();
      
      final postId = "${post['timestamp']}_${contentOrig.length}";
      
      if (notifiedPosts.contains(postId)) continue;
      
      bool isAdvisory = keywords.any((k) => contentLow.contains(k));
      if (isAdvisory) {
        NotificationService().showScheduleNotification(
           id: postId.hashCode.abs() % 10000,
           title: "⚠️ Rail Advisory: ${widget.line}",
           body: "Critical update found in Official Feed: ${contentOrig.length > 50 ? contentOrig.substring(0, 50) + '...' : contentOrig}",
        );
        notifiedPosts.add(postId);
        hasNewAdvisory = true;
      }
    }

    if (hasNewAdvisory) {
      if (notifiedPosts.length > 50) {
        notifiedPosts.removeRange(0, notifiedPosts.length - 50);
      }
      await prefs.setStringList('notified_advisories', notifiedPosts);
    }
  }

  Future<void> _scrapeData() async {
    if (!mounted) return;
    const String script = r"""
      (function() {
        try {
          const seeMoreLinks = document.querySelectorAll('._5v47, .see_more_link, [role="button"]');
          seeMoreLinks.forEach(link => {
            const text = link.innerText.toLowerCase();
            if (text.includes('see more') || text.includes('higit pa') || text.includes('continue reading')) link.click();
          });

          const posts = [];
          const postElements = document.querySelectorAll('._5pcr, .userContentWrapper, [role="article"]');
          
          postElements.forEach(el => {
            const contentEl = el.querySelector('._5pbx, .userContent, [data-testid="post_message"]');
            if (!contentEl) return;

            const timeEl = el.querySelector('abbr._39g5, ._5ptz, .timestampContent');
            const imgEls = el.querySelectorAll('img[src*="fbcdn"]');
            const imageUrls = [];
            imgEls.forEach(img => {
               if (img.width > 200 || img.height > 200) {
                 if (!imageUrls.includes(img.src)) imageUrls.push(img.src);
               }
            });

            const linkEl = el.querySelector('a._5pcq, a[href*="/posts/"], a[href*="/photos/"]');
            const postUrl = linkEl ? linkEl.href : null;

            let cleanText = contentEl.innerText.trim();
            cleanText = cleanText.replace(/See more|Higit pa|Continue reading|\.\.\.$/gi, '').trim();

            if (cleanText.length > 5 || imageUrls.length > 0) {
              posts.push({
                'content': cleanText,
                'timestamp': timeEl ? timeEl.innerText : "Latest Update",
                'imageUrls': imageUrls,
                'postUrl': postUrl
              });
            }
          });
          LRT_Scraper.postMessage(JSON.stringify(posts));
        } catch(e) { LRT_Scraper.postMessage(JSON.stringify([])); }
      })();
    """;
    await _webController.runJavaScript(script);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.orange),
                const SizedBox(height: 16),
                Text("Syncing Official Feed for ${widget.line}...",
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Opacity(
              opacity: 0.01, child: WebViewWidget(controller: _webController)),
        ],
      );
    }

    if (_hasError || _scrapedPosts.isEmpty) return _buildErrorState();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _webController.reload();
      },
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _scrapedPosts.length,
        itemBuilder: (context, index) {
          final post = _scrapedPosts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    String profileAsset = "assets/image/TaraTrain_Logo.png";
    String officialName = "Official ${widget.line}";

    if (widget.line == 'LRT-1') {
      profileAsset = "assets/image/LRTA_FB.png";
      officialName = "LRT-1 Light Rail Manila Corporation";
    }
    if (widget.line == 'LRT-2') {
      profileAsset = "assets/image/LRT-2.jpg";
      officialName = "Light Rail Transit Authority-LRT Line 2";
    }
    if (widget.line == 'MRT-3') {
      profileAsset = "assets/image/MRT3.jpg";
      officialName = "DOTr MRT-3";
    }
    if (widget.line == 'PNR') {
      profileAsset = "assets/image/PNR_Logo.png";
      officialName = "Philippine National Railways";
    }

    final postContent = post['content'].toString();
    final List<dynamic> imageUrls = post['imageUrls'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4)
                    ],
                    border: Border.all(color: Colors.grey.shade100, width: 0.5),
                    image: DecorationImage(
                      image: AssetImage(profileAsset),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                              child: Text(officialName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF0D1B3E)),
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              color: Color(0xFF1877F2), size: 16),
                        ],
                      ),
                      Text("${post['timestamp'] ?? 'Latest Update'}",
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
              ],
            ),
          ),
          if (postContent.isNotEmpty)
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _ExpandableText(text: postContent)),
          if (imageUrls.isNotEmpty) _buildImageGallery(imageUrls),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [
                  Icon(Icons.thumb_up_alt_outlined,
                      size: 18, color: Colors.blueGrey),
                  SizedBox(width: 20),
                  Icon(Icons.chat_bubble_outline,
                      size: 18, color: Colors.blueGrey)
                ]),
                TextButton.icon(
                  onPressed: () async {
                    final targetUrl = post['postUrl'] ?? _fbUrls[widget.line]!;
                    if (!await launchUrl(Uri.parse(targetUrl),
                        mode: LaunchMode.externalApplication))
                      debugPrint("Could not launch $targetUrl");
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text("Full Post",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1877F2)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<dynamic> urls) {
    if (urls.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: GestureDetector(
          onTap: () => _showFullScreenImage(context, urls[0]),
          child: CachedNetworkImage(
            imageUrl: urls[0],
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: Colors.grey.shade100, height: 200),
            errorWidget: (ctx, err, stack) => const SizedBox.shrink(),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.only(right: 2),
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, urls[0]),
                  child: CachedNetworkImage(
                      imageUrl: urls[0],
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey.shade100)),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () => _showFullScreenImage(context, urls[1]),
                        child: CachedNetworkImage(
                            imageUrl: urls[1],
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey.shade100)),
                      ),
                    ),
                  ),
                  if (urls.length > 2)
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            onTap: () => _showFullScreenImage(context, urls[2]),
                            child: CachedNetworkImage(
                                imageUrl: urls[2],
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: Colors.grey.shade100)),
                          ),
                          if (urls.length > 3)
                            IgnorePointer(
                              child: Container(
                                  color: Colors.black54,
                                  child: Center(
                                      child: Text("+${urls.length - 3}",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)))),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.grey.shade300, size: 64),
          const SizedBox(height: 16),
          const Text("Unable to Sync Feed",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Please check your internet connection.",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () => setState(() => _isLoading = true),
              child: const Text("Retry")),
        ],
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;
  static const int _maxLength = 220; // Increased length

  @override
  Widget build(BuildContext context) {
    if (widget.text.length <= _maxLength)
      return Text(widget.text,
          style: const TextStyle(
              fontSize: 14, height: 1.6, color: Color(0xFF2C3E50)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isExpanded
              ? widget.text
              : "${widget.text.substring(0, _maxLength).trim()}...",
          style: const TextStyle(
              fontSize: 14, height: 1.6, color: Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(_isExpanded ? "Show Less" : "See More",
                style: const TextStyle(
                    color: Color(0xFF1877F2),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ),
      ],
    );
  }
}
