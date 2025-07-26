import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart' as xml;
import '../models/idea.dart';

class Hexagon extends StatefulWidget {
  final Idea idea;
  final double width;
  final double height;

  Hexagon({required this.idea, required this.width, required this.height});

  @override
  _HexagonState createState() => _HexagonState();
}

class _HexagonState extends State<Hexagon> {
  String? _modifiedSvgString;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  @override
  void didUpdateWidget(covariant Hexagon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.idea != oldWidget.idea) {
      _loadSvg();
    }
  }

  void _loadSvg() {
    _loadAndModifySvg().then((svgString) {
      setState(() {
        _modifiedSvgString = svgString;
      });
    });
  }

  Future<String> _loadAndModifySvg() async {
    try {
      // Load the SVG file as a string
      String svgAsset = widget.idea.filled
          ? 'assets/single_hexagon_filled.svg'
          : 'assets/single_hexagon_unfilled.svg';
      String svgString = await rootBundle.loadString(svgAsset);

      // Parse the SVG string
      final svgXml = xml.XmlDocument.parse(svgString);

      // Ensure the xmlns attribute is present
      _ensureSvgNamespace(svgXml);

      // Modify colors
      _modifySvgColors(svgXml);

      // Convert back to string
      String modifiedSvgString = svgXml.toXmlString(
        pretty: false,
        indent: '',
      );

      // Prepend the XML declaration manually
      modifiedSvgString =
          '<?xml version="1.0" encoding="UTF-8"?>\n' + modifiedSvgString;

      return modifiedSvgString;
    } catch (e, stackTrace) {
      print('Error in _loadAndModifySvg: \$e');
      print(stackTrace);
      return ''; // Return an empty string or handle the error appropriately
    }
  }

  void _ensureSvgNamespace(xml.XmlDocument svgXml) {
    final svgElement = svgXml.rootElement;
    if (svgElement.getAttribute('xmlns') == null) {
      svgElement.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
    }
  }

  void _modifySvgColors(xml.XmlDocument svgXml) {
    final colorMap = {
      'outerHexagon': '#B45D00',
      'middleHexagon': '#F5C12F',
      'topStripe': '#FCD053',
      'bottomStripe': '#F19901',
      'innerHexagon': '#F5C12F',
      'abstractShape': '#F5A92F',
      'topBar': '#FFE6C5',
      'wavyDetail': '#FFE6C5'
    };

    // Traverse and modify the SVG elements
    for (var element in svgXml.findAllElements('*')) {
      final id = element.getAttribute('id');
      if (id != null && colorMap.containsKey(id)) {
        element.setAttribute('fill', colorMap[id]!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_modifiedSvgString != null && _modifiedSvgString!.isNotEmpty) {
      return SizedBox(
        width: widget.width * 1.15,
        height: widget.height * 1.15,
        child: Stack(
          children: [
            SvgPicture.string(
              _modifiedSvgString!,
              width: widget.width * 1.15,
              height: widget.height * 1.15,
              fit: BoxFit.fill,
            ),
            Center(
              child: Text(
                widget.idea.title,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    } else {

      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(child: CircularProgressIndicator()),
      );
    }
  }
}