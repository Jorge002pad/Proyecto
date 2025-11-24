#!/usr/bin/perl
# SIM-RED EXTENDIDO - HTML Report Generator
# Generates HTML reports from network monitoring data

use strict;
use warnings;
use POSIX qw(strftime);

# Get report data file from command line
my $data_file = $ARGV[0] || die "Usage: $0 <data_file>\n";
my $output_file = $ARGV[1] || "report.html";

# Read data file
open(my $fh, '<', $data_file) or die "Cannot open $data_file: $!\n";
my @lines = <$fh>;
close($fh);

# Parse data sections
my %data;
my $current_section = '';

foreach my $line (@lines) {
    chomp $line;
    
    if ($line =~ /^\[(\w+)\]$/) {
        $current_section = $1;
        $data{$current_section} = [];
    } elsif ($current_section && $line =~ /\S/) {
        push @{$data{$current_section}}, $line;
    }
}

# Generate HTML
my $html = generate_html(\%data);

# Write output
open(my $out, '>', $output_file) or die "Cannot write to $output_file: $!\n";
print $out $html;
close($out);

print "HTML report generated: $output_file\n";

# HTML generation function
sub generate_html {
    my ($data) = @_;
    
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
    
    my $html = <<'HTML';
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SIM-RED EXTENDIDO - Reporte de Red</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        header {
            background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        header .timestamp {
            font-size: 1.1em;
            opacity: 0.9;
        }
        
        .content {
            padding: 30px;
        }
        
        .section {
            margin-bottom: 40px;
        }
        
        .section h2 {
            color: #2c3e50;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
            margin-bottom: 20px;
            font-size: 1.8em;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        table th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
        }
        
        table td {
            padding: 12px 15px;
            border-bottom: 1px solid #e0e0e0;
        }
        
        table tbody tr:hover {
            background-color: #f5f5f5;
        }
        
        .status-ok {
            color: #27ae60;
            font-weight: bold;
        }
        
        .status-warning {
            color: #f39c12;
            font-weight: bold;
        }
        
        .status-error {
            color: #e74c3c;
            font-weight: bold;
        }
        
        .alert {
            padding: 15px;
            border-radius: 5px;
            margin: 10px 0;
        }
        
        .alert-success {
            background-color: #d4edda;
            border-left: 4px solid #28a745;
            color: #155724;
        }
        
        .alert-warning {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            color: #856404;
        }
        
        .alert-danger {
            background-color: #f8d7da;
            border-left: 4px solid #dc3545;
            color: #721c24;
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }
        
        .stat-card h3 {
            font-size: 2em;
            margin-bottom: 5px;
        }
        
        .stat-card p {
            opacity: 0.9;
        }
        
        footer {
            background: #2c3e50;
            color: white;
            text-align: center;
            padding: 20px;
            margin-top: 30px;
        }
        
        pre {
            background: #f4f4f4;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            border-left: 4px solid #667eea;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔒 SIM-RED EXTENDIDO</h1>
            <p class="timestamp">Reporte de Seguridad y Monitoreo de Red</p>
HTML

    $html .= "            <p class=\"timestamp\">Generado: $timestamp</p>\n";
    $html .= <<'HTML';
        </header>
        
        <div class="content">
HTML

    # Add sections based on data
    if (exists $data->{SUMMARY}) {
        $html .= generate_summary_section($data->{SUMMARY});
    }
    
    if (exists $data->{DEVICES}) {
        $html .= generate_devices_section($data->{DEVICES});
    }
    
    if (exists $data->{SPOOFING}) {
        $html .= generate_spoofing_section($data->{SPOOFING});
    }
    
    if (exists $data->{VPN}) {
        $html .= generate_vpn_section($data->{VPN});
    }
    
    if (exists $data->{LATENCY}) {
        $html .= generate_latency_section($data->{LATENCY});
    }
    
    if (exists $data->{TRAFFIC}) {
        $html .= generate_traffic_section($data->{TRAFFIC});
    }
    
    if (exists $data->{PORTS}) {
        $html .= generate_ports_section($data->{PORTS});
    }
    
    if (exists $data->{ALERTS}) {
        $html .= generate_alerts_section($data->{ALERTS});
    }

    $html .= <<'HTML';
        </div>
        
        <footer>
            <p>&copy; 2025 SIM-RED EXTENDIDO - Sistema de Análisis y Seguridad de Red</p>
            <p>Generado automáticamente por report_generator.pl</p>
        </footer>
    </div>
</body>
</html>
HTML

    return $html;
}

sub generate_summary_section {
    my ($data) = @_;
    
    my $html = <<'HTML';
            <div class="section">
                <h2>📊 Resumen Ejecutivo</h2>
                <div class="stats">
HTML
    
    foreach my $line (@$data) {
        if ($line =~ /^(.+?):\s*(.+)$/) {
            my ($label, $value) = ($1, $2);
            $html .= <<HTML;
                    <div class="stat-card">
                        <h3>$value</h3>
                        <p>$label</p>
                    </div>
HTML
        }
    }
    
    $html .= <<'HTML';
                </div>
            </div>
HTML
    
    return $html;
}

sub generate_devices_section {
    my ($data) = @_;
    
    my $html = <<'HTML';
            <div class="section">
                <h2>💻 Dispositivos Conectados</h2>
                <table>
                    <thead>
                        <tr>
                            <th>IP</th>
                            <th>MAC</th>
                            <th>Hostname</th>
                            <th>Estado</th>
                        </tr>
                    </thead>
                    <tbody>
HTML
    
    foreach my $line (@$data) {
        my ($ip, $mac, $hostname, $status) = split(/\|/, $line);
        my $status_class = $status eq 'OK' ? 'status-ok' : 
                          $status eq 'WARNING' ? 'status-warning' : 'status-error';
        
        $html .= <<HTML;
                        <tr>
                            <td>$ip</td>
                            <td>$mac</td>
                            <td>$hostname</td>
                            <td class="$status_class">$status</td>
                        </tr>
HTML
    }
    
    $html .= <<'HTML';
                    </tbody>
                </table>
            </div>
HTML
    
    return $html;
}

sub generate_spoofing_section {
    my ($data) = @_;
    
    my $html = <<'HTML';
            <div class="section">
                <h2>🛡️ Detección de Suplantación</h2>
HTML
    
    if (@$data == 0 || $data->[0] =~ /No se detectaron/) {
        $html .= <<'HTML';
                <div class="alert alert-success">
                    ✓ No se detectaron intentos de suplantación de IP o MAC
                </div>
HTML
    } else {
        $html .= <<'HTML';
                <div class="alert alert-danger">
                    ⚠️ Se detectaron posibles intentos de suplantación:
                </div>
                <pre>
HTML
        foreach my $line (@$data) {
            $html .= "$line\n";
        }
        $html .= <<'HTML';
                </pre>
HTML
    }
    
    $html .= "            </div>\n";
    return $html;
}

sub generate_vpn_section {
    my ($data) = @_;
    
    my $html = <<'HTML';
            <div class="section">
                <h2>🔐 Detección de VPN/Proxy</h2>
                <table>
                    <thead>
                        <tr>
                            <th>IP</th>
                            <th>Indicadores</th>
                            <th>Probabilidad</th>
                        </tr>
                    </thead>
                    <tbody>
HTML
    
    foreach my $line (@$data) {
        my ($ip, $indicators, $probability) = split(/\|/, $line);
        $html .= <<HTML;
                        <tr>
                            <td>$ip</td>
                            <td>$indicators</td>
                            <td>$probability</td>
                        </tr>
HTML
    }
    
    $html .= <<'HTML';
                    </tbody>
                </table>
            </div>
HTML
    
    return $html;
}

sub generate_latency_section {
    my ($data) = @_;
    
    my $html = <<'HTML';
            <div class="section">
                <h2>⚡ Latencia de Red</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Host</th>
                            <th>Mín (ms)</th>
                            <th>Promedio (ms)</th>
                            <th>Máx (ms)</th>
                            <th>Estado</th>
                        </tr>
                    </thead>
                    <tbody>
HTML
    
    foreach my $line (@$data) {
        my ($host, $min, $avg, $max, $status) = split(/\|/, $line);
        my $status_class = $avg < 50 ? 'status-ok' : 
                          $avg < 100 ? 'status-warning' : 'status-error';
        
        $html .= <<HTML;
                        <tr>
                            <td>$host</td>
                            <td>$min</td>
                            <td class="$status_class">$avg</td>
                            <td>$max</td>
                            <td class="$status_class">$status</td>
                        </tr>
HTML
    }
    
    $html .= <<'HTML';
                    </tbody>
                </table>
            </div>
HTML
    
    return $html;
}

sub generate_traffic_section {
    my ($data) = @_;
    
    my $html = <<'HTML';
            <div class="section">
                <h2>📈 Tráfico de Red</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Interfaz</th>
                            <th>Subida</th>
                            <th>Bajada</th>
                            <th>Total</th>
                        </tr>
                    </thead>
                    <tbody>
HTML
    
    foreach my $line (@$data) {
        my ($iface, $upload, $download, $total) = split(/\|/, $line);
        $html .= <<HTML;
                        <tr>
                            <td>$iface</td>
                            <td>$upload</td>
                            <td>$download</td>
                            <td>$total</td>
                        </tr>
HTML
    }
    
    $html .= <<'HTML';
                    </tbody>
                </table>
            </div>
HTML
    
    return $html;
}

sub generate_ports_section {
    my ($data) = @_;
    
    my $html = <<'HTML';
            <div class="section">
                <h2>🔌 Puertos Abiertos</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Host</th>
                            <th>Puerto</th>
                            <th>Servicio</th>
                            <th>Estado</th>
                        </tr>
                    </thead>
                    <tbody>
HTML
    
    foreach my $line (@$data) {
        my ($host, $port, $service, $status) = split(/\|/, $line);
        my $status_class = $status eq 'ESPERADO' ? 'status-ok' : 'status-warning';
        
        $html .= <<HTML;
                        <tr>
                            <td>$host</td>
                            <td>$port</td>
                            <td>$service</td>
                            <td class="$status_class">$status</td>
                        </tr>
HTML
    }
    
    $html .= <<'HTML';
                    </tbody>
                </table>
            </div>
HTML
    
    return $html;
}

sub generate_alerts_section {
    my ($data) = @_;
    
    my $html = <<'HTML';
            <div class="section">
                <h2>🚨 Alertas Recientes</h2>
HTML
    
    foreach my $line (@$data) {
        my $alert_class = $line =~ /ERROR|CRITICAL/i ? 'alert-danger' :
                         $line =~ /WARNING/i ? 'alert-warning' : 'alert-success';
        
        $html .= <<HTML;
                <div class="alert $alert_class">
                    $line
                </div>
HTML
    }
    
    $html .= "            </div>\n";
    return $html;
}
