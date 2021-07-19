# target-turner

A target turner for ISSF and Service Pistol competitions, using an 8085 CPU.

# purpose

<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://github.com/feilipu/target-turner/blob/master/IMG_1508.JPG" target="_blank"><img src="https://github.com/feilipu/target-turner/blob/master/IMG_1508_small.JPG"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>ISSF Target Turner - Front Panel<center></th>
</tr>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://github.com/feilipu/target-turner/blob/master/647599520.915332.jpg" target="_blank"><img src="https://github.com/feilipu/target-turner/blob/master/647599520.915332.jpg"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>ISSF Target Turner - Instructions for Use<center></th>
</tr>
</tbody>
</table>
</div>

To manage timing for target setting for ISSF and Service Pistol competitions.

# usage

<div>
<table style="border: 2px solid #cccccc;">
<tbody>
<tr>
<td style="border: 1px solid #cccccc; padding: 6px;"><a href="https://github.com/feilipu/target-turner/blob/master/IMG_1495.JPG" target="_blank"><img src="https://github.com/feilipu/target-turner/blob/master/IMG_1495_small.JPG"/></a></td>
</tr>
<tr>
<th style="border: 1px solid #cccccc; padding: 6px;"><centre>ISSF Target Turner - 8085 PCB<center></th>
</tr>
</tbody>
</table>
</div>

```
8085A A12 goes through 7404 1->2 to 8155 /CE
RAM is located from $1000 to $1100

8155 Command / Status is above $08 (xxxxx000b) I/O address
PA Register xxxxx001b
PB Register xxxxx010b
PC Register xxxxx011b
Timer Register LSB xxxxx100b
Timer Register MSB xxxxx101b

TRAP (RST 4.5)    24h
RST 5.5           2Ch
RST 6.5           34h
RST 7.5           3Ch

Interface Port
                                      IN
 _________________________________________
| GND | 5V  | IR  | TR  | 5.5 | 6.5 | 7.5 |
|_____|_____|_____|_____|_____|_____|_____|
| GND | 5V  | A0  | SOD | RST | SID | RDY |
|_____|_____|_____|_____|_____|_____|_____|
              OUT         IN

I/O Port
  IN    IN    IN
 _________________________________________
| B0  | B2  | B4  | B6  | A7  | A5  | A3  |
|_____|_____|_____|_____|_____|_____|_____|
| C0  | B1  | B3  | B5  | B7  | A6  | A4  |
|_____|_____|_____|_____|_____|_____|_____|
        IN                            OUT
```

# credits

Whomever built the original product. If it is you, or you recognise it, please let me know.

# licence

MIT License
