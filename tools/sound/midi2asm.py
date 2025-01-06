#!/usr/bin/env python3
import binascii
import sys
import os


#Convert from Midi to Assembly for Apple ( work with JF assembly route for PlaySong )
#Support Midi Octave 2 starting From Note G up to Octave 7 F#  
	# few notes in Octave 7 ( from B to E# included) are also not supported ... See Hi-Res Book Page 200 for more details
	# octave 2 to 7 is assuming we start counting them at C-1 ( and not C0 )  ...
# you midi song must have a track with tempo, the first tempo will be taken as it not support tempo change
# all note can't overlap in your melody
# all track must be contain in a single track
# the file will generate bytes to put in your assembly, the first byte is the number of notes in the melody, all subsquent bytes are 2 bytes tupple [duration, pitch ] for each notes
#test done using https://signalmidi.app/?lang=en

class Header:
    def __init__(self, hexa, number_of_tracks, ticks_per_quarter, bpm=None, assembly_note_tick=None):
        self.hexa = hexa
        self.number_of_tracks = number_of_tracks
        self.ticks_per_quarter = ticks_per_quarter
        self.bpm = bpm
        self.assembly_note_tick = assembly_note_tick

class Event:
    def __init__(self, delta, hexa, code, name, value_hexa):
        self.delta = delta
        self.hexa = hexa
        self.code = f"{code:02X}"
        self.name = name
        self.value_hexa = value_hexa

class Control:
    def __init__(self, delta, hexa, code, name, value_hexa):
        self.delta = delta
        self.hexa = hexa
        self.code = f"{code:02X}"
        self.name = name
        self.value_hexa = value_hexa

class Note:
    def __init__(self, delta, hexa, state, pitch):
        self.delta = delta
        self.hexa = hexa
        self.state = state
        self.pitch = f"{pitch:02X}"

class Track:
    def __init__(self, hexa):
        self.hexa = hexa
        self.events = []
        self.controls = []
        self.notes = []


class AssemblyNoteLookup:
    def __init__(self):
        # Lookup table for pitch values, organized by octave
        self.pitch_table = {
            2: {"G": 255, "A#": 243, "A": 231, "B#": 217, "B": 203},
            3: {"C": 192, "C#": 182, "D": 172, "E#": 162, "E": 154, "F": 146, "F#": 137, "G": 128, "A#": 121, "A": 114, "B#": 108, "B": 102},
            4: {"C": 96, "C#": 90, "D": 85, "E#": 80, "E": 76, "F": 72, "F#": 67, "G": 64, "A#": 60, "A": 56, "B#": 53, "B": 50},
            5: {"C": 47, "C#": 45, "D": 42, "E#": 40, "E": 37, "F": 35, "F#": 33, "G": 31, "A#": 29, "A": 28, "B#": 26, "B": 25},
            6: {"C": 23, "C#": 22, "D": 21, "E#": 20, "E": 18, "F": 17, "F#": 16, "G": 15, "A#": 14, "A": 13, "B#": 12, "B": 11},
            7: {"E": 11, "F": 10, "F#": 9 }
        }

    def get_pitch(self, note, octave):
        """
        Retrieve the pitch value for a given note and octave from midi protocal.
        the pitch value is the ApplieIIe pitch 
        If the note or octave is out of range, return an error.
        """
        if octave not in self.pitch_table:
            print (f"Error: Unsupported octave. Octave must be between 3 and 8.")
            os._exit(1)
        if note not in self.pitch_table[octave]:
            print (f"Error: Note '{note}' is unsupported in octave {octave}.")
            os._exit(1)
            
        return self.pitch_table[octave][note]

    def midi_note_lookup(self, note_byte):
        notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return notes[int(note_byte, 16) % 12] 

    def midi_octave_lookup(self, note_byte):
        return int(note_byte, 16) // 12 - 1 # octave start at -1




class MIDIParser:
    def __init__(self, midi_data):
        self.raw_data = midi_data
        self.header = None
        self.tracks = []

    def parse(self):
        offset = 0

        # Parse Header Chunk
        header_id = self.raw_data[offset:offset+4]
        offset += 4
        if header_id != b"MThd":
            raise ValueError("Invalid MIDI file header")

        header_length = int.from_bytes(self.raw_data[offset:offset+4], byteorder="big")
        offset += 4
        header_data = self.raw_data[offset:offset+header_length]
        offset += header_length

        format_type = int.from_bytes(header_data[0:2], byteorder="big")
        number_of_tracks = int.from_bytes(header_data[2:4], byteorder="big")
        ticks_per_quarter = int.from_bytes(header_data[4:6], byteorder="big")

        self.header = Header(
            hexa=binascii.hexlify(header_data).decode(),
            number_of_tracks=number_of_tracks,
            ticks_per_quarter=ticks_per_quarter
        )

        # Parse Track Chunks
        for _ in range(number_of_tracks):
            track_id = self.raw_data[offset:offset+4]
            offset += 4
            if track_id != b"MTrk":
                raise ValueError("Invalid MIDI track header")

            track_length = int.from_bytes(self.raw_data[offset:offset+4], byteorder="big")
            offset += 4
            track_data = self.raw_data[offset:offset+track_length]
            offset += track_length

            track = Track(hexa=binascii.hexlify(track_data).decode())
            self.parse_track(track, track_data)
            self.tracks.append(track)

    def parse_track(self, track, track_data):
        offset = 0

        while offset < len(track_data):
            # Parse Delta Time
            delta_time = 0
            while True:
                delta_byte = track_data[offset]
                offset += 1
                delta_time = (delta_time << 7) | (delta_byte & 0x7F)
                if not (delta_byte & 0x80):
                    break

            # Parse Event
            event_start = offset
            event_type = track_data[offset]
            offset += 1

            if event_type == 0xFF:  # Meta Event
                meta_type = track_data[offset]
                offset += 1
                length = track_data[offset]
                offset += 1
                value = track_data[offset:offset+length]
                offset += length
                name = self.get_meta_event_name(meta_type)
                event = Event(
                    delta=delta_time,
                    hexa=binascii.hexlify(track_data[event_start:offset]).decode(),
                    code=meta_type,
                    name=name,
                    value_hexa=binascii.hexlify(value).decode()
                )
                track.events.append(event)

                if meta_type == 0x51 and self.header.bpm is None:  # Tempo event
                    tempo_microseconds = int.from_bytes(value, byteorder="big")
                    bpm = 60000000 // tempo_microseconds
                    self.header.bpm = bpm

            elif event_type >= 0x80 and event_type < 0xF0:  # MIDI Event
                channel = event_type & 0x0F
                event_code = (event_type & 0xF0) >> 4
                name, length = self.get_midi_event_name_and_length(event_code)
                value = track_data[offset:offset+length]
                offset += length

                if event_code in (0x8, 0x9):  # Note On/Off
                    state = "on" if event_code == 0x9 else "off"
                    pitch = value[0]
                    note = Note(
                        delta=delta_time,
                        hexa=binascii.hexlify(track_data[event_start:offset]).decode(),
                        state=state,
                        pitch=pitch
                    )
                    track.notes.append(note)
                else:  # Control Change
                    control = Control(
                        delta=delta_time,
                        hexa=binascii.hexlify(track_data[event_start:offset]).decode(),
                        code=event_code,
                        name=name,
                        value_hexa=binascii.hexlify(value).decode()
                    )
                    track.controls.append(control)

    def get_meta_event_name(self, meta_type):
        meta_event_names = {
            0x2F: "End of Track",
            0x51: "Tempo",
            0x58: "Time Signature"
        }
        return meta_event_names.get(meta_type, "Unknown Meta Event")

    def get_midi_event_name_and_length(self, event_code):
        midi_event_names = {
            0x8: ("Note Off", 2),
            0x9: ("Note On", 2),
            0xA: ("Polyphonic Key Pressure", 2),
            0xB: ("Control Change", 2),
            0xC: ("Program Change", 1),
            0xD: ("Channel Pressure", 1),
            0xE: ("Pitch Bend", 2)
        }
        return midi_event_names.get(event_code, ("Unknown MIDI Event", 0))

    def build_note_stack(self):
        note_stack = []

        ticks_per_second = self.header.ticks_per_quarter * (self.header.bpm / 60)
        full_note_tick = self.header.ticks_per_quarter * 4  # Full note tick duration
        
        #self.header.bpm = 100
        
        self.header.assembly_note_tick = round(960 / (self.header.bpm / 100))
	
	
        assemblyLookup = AssemblyNoteLookup()
      
        for track in self.tracks:
            pending_note = None

            for note in track.notes:
                if note.state == "on":
                    if note.delta != 0 and pending_note is None:
                        # Silence duration
                        duration = round(note.delta / (full_note_tick / self.header.assembly_note_tick) )
                        note_stack.append({	"tick": note.delta, 
                        			"assembly_duration": f"{duration:02X}", 
                        			"pitch": "00", 
                        			"assembly_pitch": "00"})
                    pending_note = note
                elif note.state == "off" and pending_note:
                    # Note duration
                    duration = round(note.delta / (full_note_tick / self.header.assembly_note_tick) )
                    note_string = assemblyLookup.midi_note_lookup(pending_note.pitch)

                    octave = assemblyLookup.midi_octave_lookup(pending_note.pitch)
                    #print(note_string)
                    #print(octave)                    
                    note_stack.append({	"tick": note.delta, 
                    				"assembly_duration": f"{duration:02X}", 
                    				"pitch": pending_note.pitch, 
                    				"assembly_pitch": f"{assemblyLookup.get_pitch(note_string, octave):02X}",
                    				"note": note_string, 
                    				"octave": octave })
                    pending_note = None

        return note_stack


    def print_parsed_data(self):
        print("Header:")
        print(f"  Hexa: {self.header.hexa}")
        print(f"  Number of Tracks: {self.header.number_of_tracks}")
        print(f"  Ticks Per Quarter: {self.header.ticks_per_quarter}")
        print(f"  Assembly Tick (based on BPM): {self.header.assembly_note_tick}")
        if self.header.bpm:
            print(f"  Tempo (BPM): {self.header.bpm}")

        for i, track in enumerate(self.tracks):
            print(f"\nTrack {i+1}:")
            print(f"  Hexa: {track.hexa}")

            print("  Events:")
            for event in track.events:
                print(f"    Delta: {event.delta}, Hexa: {event.hexa}, Code: {event.code}, Name: {event.name}, Value: {event.value_hexa}")


    def generate_assembly_code(self, filename):
        note_stack = self.build_note_stack()
        note_count = len(note_stack)
        base_name = filename.split(".")[0]

        assembly = f"; This is a track of {note_count} Notes, at {self.header.bpm} bpm, strucutre is [notes_count] [notes_data...], each notes is 2 bytes [duration,pitch]\n"
        assembly += f"{base_name}Song hex {note_count:02X}"

        for note in note_stack:
            duration = note.get("assembly_duration", "00")
            pitch = note.get("assembly_pitch", "00")
            assembly += f"{duration}{pitch}"

        return assembly

# Example usage
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: ./midi_parser.py <midi_file>")
        sys.exit(1)

    filename = sys.argv[1]

    try:
        with open(filename, "rb") as f:
            midi_hex = f.read()
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
        sys.exit(1)

    parser = MIDIParser(midi_hex)
    parser.parse()
   

    # Build and print note stack
    note_stack = parser.build_note_stack()
    
    parser.print_parsed_data()
    print("\nNote Stack:")
    for record in note_stack:
        print(record)

    # Generate and print assembly code
    assembly_code = parser.generate_assembly_code(filename)
    print("\nAssembly Code:")
    print(assembly_code)

